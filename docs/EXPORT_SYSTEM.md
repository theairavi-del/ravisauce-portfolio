# Export System Technical Specification

## Overview
The Export System handles generating modified HTML/CSS from the edited project and packaging assets into downloadable formats (ZIP or individual files).

---

## Export Formats

| Format | Extension | Use Case | Priority |
|--------|-----------|----------|----------|
| ZIP Archive | `.zip` | Complete website bundle | Critical |
| HTML File | `.html` | Single page export | Critical |
| CSS Files | `.css` | Stylesheet export | High |
| Static Site | folder | Ready-to-deploy | High |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         EXPORT PIPELINE                                  │
└─────────────────────────────────────────────────────────────────────────┘

   Project Data (Layer Tree + DOM)
            │
            ▼
   ┌─────────────────┐
   │  HTML Generator │
   │                 │
   │  • Serialize    │
   │    DOM tree     │
   │  • Inline       │
   │    modified     │
   │    styles       │
   │  • Preserve     │
   │    structure    │
   └────────┬────────┘
            │
            │ Modified HTML
            ▼
   ┌─────────────────┐
   │  CSS Generator  │
   │                 │
   │  • Extract      │
   │    inline       │
   │    styles       │
   │  • Merge with   │
   │    external     │
   │    stylesheets  │
   │  • Optimize     │
   │    selectors    │
   └────────┬────────┘
            │
            │ CSS Files
            ▼
   ┌─────────────────┐
   │  Asset Bundler  │
   │                 │
   │  • Collect      │
   │    referenced   │
   │    assets       │
   │  • Copy to      │
   │    output       │
   │    folder       │
   │  • Update URLs  │
   └────────┬────────┘
            │
            │ Asset Files
            ▼
   ┌─────────────────┐
   │  ZIP Packager   │
   │                 │
   │  • Create       │
   │    archive      │
   │  • Stream       │
   │    chunks       │
   │  • Generate     │
   │    download     │
   └────────┬────────┘
            │
            ▼
       ZIP File
```

---

## Core Classes

### 1. HTML Generator

```typescript
// src/core/export/HTMLGenerator.ts

interface HTMLGenerationOptions {
  format: 'pretty' | 'minified';
  includeComments: boolean;
  inlineStyles: boolean;
  preserveClasses: boolean;
  removeEmptyAttributes: boolean;
  scriptHandling: 'preserve' | 'remove' | 'externalize';
}

interface GeneratedHTML {
  content: string;
  warnings: string[];
  stats: {
    originalSize: number;
    generatedSize: number;
    elementCount: number;
  };
}

class HTMLGenerator {
  private options: HTMLGenerationOptions;
  
  constructor(options: Partial<HTMLGenerationOptions> = {}) {
    this.options = {
      format: 'pretty',
      includeComments: false,
      inlineStyles: false,
      preserveClasses: true,
      removeEmptyAttributes: true,
      scriptHandling: 'preserve',
      ...options
    };
  }
  
  // Main generation
  async generate(project: Project): Promise<GeneratedHTML> {
    const doc = project.html.html.cloneNode(true) as Document;
    const originalSize = this.getDocumentSize(doc);
    
    // Apply all layer modifications to the DOM
    this.applyLayerModifications(doc, project.rootLayer);
    
    // Process based on options
    if (this.options.inlineStyles) {
      this.inlineAllStyles(doc);
    }
    
    if (this.options.removeEmptyAttributes) {
      this.removeEmptyAttributes(doc);
    }
    
    if (!this.options.includeComments) {
      this.removeComments(doc);
    }
    
    // Handle scripts
    this.processScripts(doc);
    
    // Serialize
    const content = this.serializeDocument(doc);
    const generatedSize = new Blob([content]).size;
    
    return {
      content,
      warnings: [],
      stats: {
        originalSize,
        generatedSize,
        elementCount: doc.querySelectorAll('*').length
      }
    };
  }
  
  // Apply modifications from layer tree to DOM
  private applyLayerModifications(doc: Document, layer: Layer): void {
    const element = this.findElementByPath(doc, layer.domPath);
    if (!element) return;
    
    // Apply visibility
    if (!layer.visible) {
      element.setAttribute('style', this.addStyle(element, 'display: none'));
    }
    
    // Apply transform
    if (layer.transform) {
      const transformCSS = this.transformToCSS(layer.transform);
      element.setAttribute('style', this.addStyle(element, transformCSS));
    }
    
    // Apply content changes
    if (layer.type === LayerType.TEXT && layer.content?.textContent) {
      element.textContent = layer.content.textContent;
    }
    
    if (layer.type === LayerType.IMAGE) {
      if (layer.content?.src) {
        (element as HTMLImageElement).src = layer.content.src;
      }
      if (layer.content?.alt) {
        (element as HTMLImageElement).alt = layer.content.alt;
      }
    }
    
    // Apply computed styles
    Object.entries(layer.computedStyles).forEach(([property, value]) => {
      (element as HTMLElement).style[property as any] = value;
    });
    
    // Recurse into children
    layer.children.forEach(child => this.applyLayerModifications(doc, child));
  }
  
  private transformToCSS(transform: Transform): string {
    const parts: string[] = [];
    
    if (transform.x !== 0 || transform.y !== 0) {
      parts.push(`transform: translate(${transform.x}px, ${transform.y}px)`);
    }
    
    if (transform.rotation !== 0) {
      parts.push(`rotate(${transform.rotation}deg)`);
    }
    
    if (transform.width) {
      parts.push(`width: ${transform.width}px`);
    }
    
    if (transform.height) {
      parts.push(`height: ${transform.height}px`);
    }
    
    return parts.join('; ');
  }
  
  private addStyle(element: Element, newStyle: string): string {
    const current = element.getAttribute('style') || '';
    return current ? `${current}; ${newStyle}` : newStyle;
  }
  
  private findElementByPath(doc: Document, path: string): Element | null {
    // Convert stored path to selector
    try {
      return doc.querySelector(path);
    } catch {
      // Fallback to manual traversal if selector is invalid
      return this.traversePath(doc.documentElement, path.split(' > '));
    }
  }
  
  private traversePath(root: Element, pathParts: string[]): Element | null {
    let current: Element = root;
    
    for (const part of pathParts) {
      const children = Array.from(current.children);
      const match = children.find(child => this.matchesPart(child, part));
      if (!match) return null;
      current = match;
    }
    
    return current;
  }
  
  private matchesPart(element: Element, part: string): boolean {
    const tagName = part.split(/[.#]/)[0];
    return element.tagName.toLowerCase() === tagName.toLowerCase();
  }
  
  private serializeDocument(doc: Document): string {
    const doctype = doc.doctype 
      ? `<!DOCTYPE ${doc.doctype.name}>` 
      : '<!DOCTYPE html>';
    
    const html = doc.documentElement.outerHTML;
    
    if (this.options.format === 'minified') {
      return this.minifyHTML(`${doctype}\n${html}`);
    }
    
    return this.prettyPrintHTML(`${doctype}\n${html}`);
  }
  
  private minifyHTML(html: string): string {
    return html
      .replace(/>\s+</g, '><')
      .replace(/\s{2,}/g, ' ')
      .replace(/<!--[\s\S]*?-->/g, '')
      .trim();
  }
  
  private prettyPrintHTML(html: string): string {
    // Simple indentation
    let indent = 0;
    const indentSize = '  ';
    
    return html
      .replace(/>\s*</g, '>\n<')
      .split('\n')
      .map(line => {
        line = line.trim();
        if (line.match(/^<\/\w/)) indent--;
        const result = indentSize.repeat(Math.max(0, indent)) + line;
        if (line.match(/^<\w[^>]*>[^<]*$/)) indent++;
        return result;
      })
      .join('\n');
  }
  
  private getDocumentSize(doc: Document): number {
    return new Blob([doc.documentElement.outerHTML]).size;
  }
  
  private inlineAllStyles(doc: Document): void {
    // Move all external styles to inline
    const styleSheets = doc.querySelectorAll('link[rel="stylesheet"]');
    styleSheets.forEach(link => link.remove());
  }
  
  private removeEmptyAttributes(doc: Document): void {
    const allElements = doc.querySelectorAll('*');
    allElements.forEach(el => {
      Array.from(el.attributes).forEach(attr => {
        if (attr.value === '' || attr.value === 'null' || attr.value === 'undefined') {
          el.removeAttribute(attr.name);
        }
      });
    });
  }
  
  private removeComments(doc: Document): void {
    const walker = doc.createTreeWalker(doc, NodeFilter.SHOW_COMMENT);
    const comments: Comment[] = [];
    while (walker.nextNode()) {
      comments.push(walker.currentNode as Comment);
    }
    comments.forEach(c => c.remove());
  }
  
  private processScripts(doc: Document): void {
    switch (this.options.scriptHandling) {
      case 'remove':
        doc.querySelectorAll('script').forEach(s => s.remove());
        break;
      case 'externalize':
        // Move inline scripts to external files (advanced)
        break;
      case 'preserve':
      default:
        // Do nothing
        break;
    }
  }
}
```

### 2. CSS Generator

```typescript
// src/core/export/CSSGenerator.ts

interface CSSGenerationOptions {
  format: 'expanded' | 'compressed';
  combineSelectors: boolean;
  removeUnused: boolean;
  autoprefix: boolean;
  sourceMap: boolean;
}

interface GeneratedCSS {
  files: Map<string, string>;  // filename -> content
  warnings: string[];
  stats: {
    totalRules: number;
    totalSelectors: number;
    totalDeclarations: number;
    originalSize: number;
    generatedSize: number;
  };
}

class CSSGenerator {
  private options: CSSGenerationOptions;
  
  constructor(options: Partial<CSSGenerationOptions> = {}) {
    this.options = {
      format: 'expanded',
      combineSelectors: true,
      removeUnused: false,
      autoprefix: false,
      sourceMap: false,
      ...options
    };
  }
  
  async generate(project: Project): Promise<GeneratedCSS> {
    const files = new Map<string, string>();
    const stylesheets: ParsedStylesheet[] = [];
    
    // Collect all styles from layers
    const layerStyles = this.extractLayerStyles(project.rootLayer);
    
    // Generate CSS for modified elements
    const modifiedCSS = this.generateModifiedCSS(layerStyles);
    
    // Merge with original stylesheets
    project.stylesheets.forEach((sheet, index) => {
      const originalCSS = this.cssParser.serialize(sheet);
      const mergedCSS = this.mergeStylesheets(originalCSS, modifiedCSS);
      
      files.set(`styles${index + 1}.css`, mergedCSS);
    });
    
    // If no stylesheets existed, create one
    if (files.size === 0) {
      files.set('styles.css', modifiedCSS);
    }
    
    return {
      files,
      warnings: [],
      stats: this.calculateStats(files)
    };
  }
  
  private extractLayerStyles(rootLayer: Layer): Map<string, CSSStyleDeclaration> {
    const styles = new Map<string, CSSStyleDeclaration>();
    
    const traverse = (layer: Layer) => {
      if (Object.keys(layer.computedStyles).length > 0) {
        styles.set(layer.domPath, layer.computedStyles);
      }
      layer.children.forEach(traverse);
    };
    
    traverse(rootLayer);
    return styles;
  }
  
  private generateModifiedCSS(styles: Map<string, CSSStyleDeclaration>): string {
    const rules: string[] = [];
    
    styles.forEach((computedStyles, selector) => {
      const declarations = Object.entries(computedStyles)
        .map(([prop, value]) => `  ${this.camelToKebab(prop)}: ${value};`)
        .join('\n');
      
      if (declarations) {
        rules.push(`${selector} {\n${declarations}\n}`);
      }
    });
    
    return rules.join('\n\n');
  }
  
  private camelToKebab(str: string): string {
    return str.replace(/[A-Z]/g, letter => `-${letter.toLowerCase()}`);
  }
  
  private mergeStylesheets(original: string, modified: string): string {
    // Simple concatenation with comment separator
    return `${original}\n\n/* Modified Styles */\n${modified}`;
  }
  
  private calculateStats(files: Map<string, string>) {
    let totalSize = 0;
    files.forEach(content => {
      totalSize += content.length;
    });
    
    return {
      totalRules: 0,  // Would need CSS parser
      totalSelectors: 0,
      totalDeclarations: 0,
      originalSize: 0,
      generatedSize: totalSize
    };
  }
}
```

### 3. Asset Bundler

```typescript
// src/core/export/AssetBundler.ts

interface AssetBundleOptions {
  optimizeImages: boolean;
  preserveStructure: boolean;
  flattenOutput: boolean;
}

interface AssetBundle {
  files: Map<string, Blob>;
  structure: AssetStructure;
  warnings: string[];
}

interface AssetStructure {
  root: string;
  folders: string[];
  files: Array<{
    path: string;
    size: number;
    type: string;
  }>;
}

class AssetBundler {
  private options: AssetBundleOptions;
  
  constructor(options: Partial<AssetBundleOptions> = {}) {
    this.options = {
      optimizeImages: false,
      preserveStructure: true,
      flattenOutput: false,
      ...options
    };
  }
  
  async bundle(project: Project): Promise<AssetBundle> {
    const files = new Map<string, Blob>();
    const structure: AssetStructure = {
      root: project.name,
      folders: [],
      files: []
    };
    
    // Collect all assets
    const assets = [
      ...project.assets,
      ...this.collectReferencedAssets(project)
    ];
    
    for (const asset of assets) {
      const outputPath = this.getOutputPath(asset);
      
      // Get blob from asset
      let blob = asset.blob;
      
      // Optimize if needed
      if (this.options.optimizeImages && this.isImage(asset.mimeType)) {
        blob = await this.optimizeImage(blob, asset.mimeType);
      }
      
      files.set(outputPath, blob);
      
      structure.files.push({
        path: outputPath,
        size: blob.size,
        type: asset.mimeType
      });
    }
    
    return { files, structure, warnings: [] };
  }
  
  private collectReferencedAssets(project: Project): ExtractedAsset[] {
    const assets: ExtractedAsset[] = [];
    const doc = project.html.html;
    
    // Find all image references
    doc.querySelectorAll('img').forEach(img => {
      const src = img.getAttribute('src');
      if (src && !src.startsWith('http') && !src.startsWith('data:')) {
        // Find matching asset
        const asset = project.assets.find(a => 
          a.originalPath === src || a.fileName === src
        );
        if (asset && !assets.includes(asset)) {
          assets.push(asset);
        }
      }
    });
    
    // Find font references in stylesheets
    // ... similar logic for fonts
    
    return assets;
  }
  
  private getOutputPath(asset: ExtractedAsset): string {
    if (this.options.flattenOutput) {
      return asset.fileName;
    }
    
    if (this.options.preserveStructure) {
      // Reconstruct original folder structure
      return asset.originalPath.replace(/^\//, '');
    }
    
    // Organize by type
    const type = asset.mimeType.split('/')[0];
    return `${type}s/${asset.fileName}`;
  }
  
  private isImage(mimeType: string): boolean {
    return mimeType.startsWith('image/');
  }
  
  private async optimizeImage(blob: Blob, mimeType: string): Promise<Blob> {
    // Would use canvas or Web Worker for optimization
    // For now, return as-is
    return blob;
  }
}
```

### 4. ZIP Packager

```typescript
// src/core/export/ZIPPackager.ts

import JSZip from 'jszip';

interface ZIPOptions {
  compression: 'DEFLATE' | 'STORE';
  compressionLevel: number;  // 1-9
}

class ZIPPackager {
  private zip: JSZip;
  
  constructor() {
    this.zip = new JSZip();
  }
  
  async createBundle(
    html: GeneratedHTML,
    css: GeneratedCSS,
    assets: AssetBundle,
    options: ZIPOptions = { compression: 'DEFLATE', compressionLevel: 6 }
  ): Promise<Blob> {
    // Add HTML
    this.zip.file('index.html', html.content);
    
    // Add CSS files
    css.files.forEach((content, filename) => {
      this.zip.file(`css/${filename}`, content);
    });
    
    // Add assets
    assets.files.forEach((blob, path) => {
      this.zip.file(path, blob);
    });
    
    // Add metadata
    this.zip.file('webbuilder.json', JSON.stringify({
      exportedAt: new Date().toISOString(),
      version: '1.0.0',
      stats: {
        htmlSize: html.stats.generatedSize,
        cssSize: Array.from(css.files.values()).reduce((a, b) => a + b.length, 0),
        assetCount: assets.files.size
      }
    }, null, 2));
    
    // Generate ZIP
    const content = await this.zip.generateAsync({
      type: 'blob',
      compression: options.compression,
      compressionOptions: {
        level: options.compressionLevel
      }
    }, (metadata) => {
      // Progress callback
      console.log(`ZIP Progress: ${metadata.percent.toFixed(1)}%`);
    });
    
    return content;
  }
  
  async createProjectExport(project: Project): Promise<Blob> {
    // Export full project data for re-import
    const projectData = this.serializeProject(project);
    this.zip.file('project.json', JSON.stringify(projectData, null, 2));
    
    // Add all assets
    project.assets.forEach(asset => {
      this.zip.file(`assets/${asset.fileName}`, asset.blob);
    });
    
    return this.zip.generateAsync({ type: 'blob' });
  }
  
  private serializeProject(project: Project): any {
    return {
      id: project.id,
      name: project.name,
      createdAt: project.createdAt,
      modifiedAt: project.modifiedAt,
      rootLayer: this.serializeLayer(project.rootLayer),
      viewport: project.viewport,
      assetIndex: project.assets.map(a => ({
        id: a.id,
        originalPath: a.originalPath,
        fileName: a.fileName,
        mimeType: a.mimeType
      }))
    };
  }
  
  private serializeLayer(layer: Layer): any {
    return {
      id: layer.id,
      type: layer.type,
      name: layer.name,
      domPath: layer.domPath,
      tagName: layer.tagName,
      visible: layer.visible,
      locked: layer.locked,
      collapsed: layer.collapsed,
      transform: layer.transform,
      computedStyles: layer.computedStyles,
      content: layer.content,
      children: layer.children.map(c => this.serializeLayer(c))
    };
  }
}
```

---

## File System Access API Integration

```typescript
// src/core/export/FileSystemExporter.ts

class FileSystemExporter {
  // Save directly to disk using File System Access API
  async saveToFolder(project: Project, handle: FileSystemDirectoryHandle): Promise<void> {
    const htmlGen = new HTMLGenerator({ format: 'pretty' });
    const cssGen = new CSSGenerator({ format: 'expanded' });
    const assetBundler = new AssetBundler();
    
    // Generate outputs
    const html = await htmlGen.generate(project);
    const css = await cssGen.generate(project);
    const assets = await assetBundler.bundle(project);
    
    // Create folder structure
    const cssFolder = await handle.getDirectoryHandle('css', { create: true });
    const assetsFolder = await handle.getDirectoryHandle('assets', { create: true });
    
    // Write HTML
    const htmlFile = await handle.getFileHandle('index.html', { create: true });
    const htmlWritable = await htmlFile.createWritable();
    await htmlWritable.write(html.content);
    await htmlWritable.close();
    
    // Write CSS files
    for (const [filename, content] of css.files) {
      const cssFile = await cssFolder.getFileHandle(filename, { create: true });
      const cssWritable = await cssFile.createWritable();
      await cssWritable.write(content);
      await cssWritable.close();
    }
    
    // Write assets
    for (const [path, blob] of assets.files) {
      const file = await assetsFolder.getFileHandle(path.split('/').pop()!, { create: true });
      const writable = await file.createWritable();
      await writable.write(blob);
      await writable.close();
    }
  }
  
  // Trigger browser download for ZIP
  downloadZIP(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
}
```

---

## Usage Example

```typescript
// src/export/index.ts

export class ExportManager {
  private htmlGenerator: HTMLGenerator;
  private cssGenerator: CSSGenerator;
  private assetBundler: AssetBundler;
  private zipPackager: ZIPPackager;
  
  constructor() {
    this.htmlGenerator = new HTMLGenerator();
    this.cssGenerator = new CSSGenerator();
    this.assetBundler = new AssetBundler();
    this.zipPackager = new ZIPPackager();
  }
  
  async exportToZIP(project: Project): Promise<void> {
    // Show progress
    this.showProgress('Generating HTML...');
    const html = await this.htmlGenerator.generate(project);
    
    this.showProgress('Generating CSS...');
    const css = await this.cssGenerator.generate(project);
    
    this.showProgress('Bundling assets...');
    const assets = await this.assetBundler.bundle(project);
    
    this.showProgress('Creating ZIP...');
    const zipBlob = await this.zipPackager.createBundle(html, css, assets);
    
    this.showProgress('Downloading...');
    const exporter = new FileSystemExporter();
    exporter.downloadZIP(zipBlob, `${project.name}.zip`);
    
    this.hideProgress();
  }
  
  async exportToFolder(project: Project): Promise<void> {
    if (!('showDirectoryPicker' in window)) {
      alert('File System Access API not supported in this browser');
      return;
    }
    
    try {
      const handle = await window.showDirectoryPicker();
      const exporter = new FileSystemExporter();
      await exporter.saveToFolder(project, handle);
    } catch (err) {
      console.log('Export cancelled');
    }
  }
  
  private showProgress(message: string): void {
    // Show loading indicator
    console.log(message);
  }
  
  private hideProgress(): void {
    // Hide loading indicator
  }
}
```

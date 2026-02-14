# File Upload System Technical Specification

## Overview
The File Upload System handles importing websites into the editor. It supports drag-drop folder uploads, parses HTML/CSS/JS, extracts assets (images, fonts), and builds a DOM tree representation.

---

## Supported Formats

| Format | Extension | Purpose | Priority |
|--------|-----------|---------|----------|
| HTML | `.html`, `.htm` | Page structure | Critical |
| CSS | `.css` | Stylesheets | Critical |
| JavaScript | `.js` | Scripts | High |
| Images | `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.webp` | Assets | Critical |
| Fonts | `.woff`, `.woff2`, `.ttf`, `.otf`, `.eot` | Typography | High |
| Data | `.json`, `.xml` | Configuration | Medium |
| Documents | `.pdf` | Embedded content | Low |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        FILE UPLOAD PIPELINE                              │
└─────────────────────────────────────────────────────────────────────────┘

   Drag/Drop or File Picker
            │
            ▼
   ┌─────────────────┐
   │  FileSystem     │
   │  Entry Reader   │
   │                 │
   │  • Recurse dirs │
   │  • Filter by    │
   │    extension    │
   │  • Build tree   │
   └────────┬────────┘
            │
            │ FileEntry[]
            ▼
   ┌─────────────────┐
   │  Asset          │
   │  Extractor      │
   │                 │
   │  • Copy binary  │
   │  • Generate     │
   │    blob URLs    │
   │  • Track refs   │
   └────────┬────────┘
            │
            │ ExtractedAssets
            ▼
   ┌─────────────────┐
   │  HTML Parser    │
   │                 │
   │  • Parse to DOM │
   │  • Rewrite URLs │
   │  • Extract      │
   │    inline CSS   │
   └────────┬────────┘
            │
            │ ParsedDocument
            ▼
   ┌─────────────────┐
   │  CSS Parser     │
   │                 │
   │  • Parse AST    │
   │  • Extract      │
   │    selectors    │
   │  • Match to     │
   │    elements     │
   └────────┬────────┘
            │
            │ StyleMap
            ▼
   ┌─────────────────┐
   │  Layer Builder  │
   │                 │
   │  • DOM → Tree   │
   │  • Assign IDs   │
   │  • Calculate    │
   │    bounds       │
   └────────┬────────┘
            │
            ▼
       Project Object
```

---

## Core Classes

### 1. File System Entry Reader

```typescript
// src/core/parser/FileSystemReader.ts

interface FileEntry {
  name: string;
  path: string;           // Relative path from root
  fullPath: string;       // Absolute path
  type: 'file' | 'directory';
  size: number;
  lastModified: number;
  content?: Blob;         // For files
  children?: FileEntry[]; // For directories
}

class FileSystemReader {
  // Drag-drop entry point
  async readDataTransfer(dataTransfer: DataTransfer): Promise<FileEntry[]>;
  
  // File System Access API entry point
  async readDirectoryHandle(handle: FileSystemDirectoryHandle): Promise<FileEntry[]>;
  
  // Traditional file input
  async readFileList(fileList: FileList): Promise<FileEntry[]>;
  
  // Internal
  private async readEntry(entry: FileSystemEntry): Promise<FileEntry>;
  private async readDirectory(entry: FileSystemDirectoryEntry): Promise<FileEntry>;
  private async readFile(entry: FileSystemFileEntry): Promise<FileEntry>;
  
  // Filtering
  private isSupportedFile(name: string): boolean;
  private getFileCategory(name: string): FileCategory;
}
```

### 2. Asset Extractor

```typescript
// src/core/parser/AssetExtractor.ts

interface ExtractedAsset {
  id: string;
  originalPath: string;
  fileName: string;
  mimeType: string;
  size: number;
  blob: Blob;
  blobUrl: string;
  usedBy: string[];       // References from HTML/CSS
}

interface AssetMap {
  images: Map<string, ExtractedAsset>;
  fonts: Map<string, ExtractedAsset>;
  other: Map<string, ExtractedAsset>;
}

class AssetExtractor {
  private assets: AssetMap;
  
  // Main extraction
  async extract(files: FileEntry[]): Promise<AssetMap>;
  
  // URL rewriting
  rewriteUrl(originalUrl: string, assetMap: AssetMap): string;
  
  // Path resolution
  resolveRelativePath(base: string, relative: string): string;
  
  // Content type detection
  detectMimeType(fileName: string, buffer?: ArrayBuffer): string;
  
  // Cleanup
  revokeAllBlobUrls(): void;
  
  // Import from existing blob URLs (for saved projects)
  importFromBlobs(blobs: Record<string, Blob>): AssetMap;
}
```

### 3. HTML Parser

```typescript
// src/core/parser/HTMLParser.ts

interface ParsedDocument {
  title: string;
  doctype: string;
  html: HTMLElement;
  head: HTMLHeadElement;
  body: HTMLBodyElement;
  stylesheets: StylesheetRef[];
  scripts: ScriptRef[];
  meta: MetaTag[];
}

interface ParseOptions {
  baseUrl?: string;
  rewriteAssetUrls: boolean;
  extractInlineStyles: boolean;
  preserveScripts: boolean;
}

class HTMLParser {
  private domParser: DOMParser;
  private assetExtractor: AssetExtractor;
  
  // Main parse
  async parse(
    htmlContent: string, 
    options: ParseOptions
  ): Promise<ParsedDocument>;
  
  // URL rewriting
  rewriteAssetUrls(
    doc: Document, 
    assetMap: AssetMap,
    basePath: string
  ): void;
  
  // Extract inline styles
  extractInlineStyles(doc: Document): CSSStyleDeclaration[];
  
  // Build link graph
  extractStylesheets(doc: Document): StylesheetRef[];
  extractScripts(doc: Document): ScriptRef[];
  
  // Sanitization
  sanitizeScripts(doc: Document): void;
  removeDangerousElements(doc: Document): void;
}
```

### 4. CSS Parser

```typescript
// src/core/parser/CSSParser.ts

import * as postcss from 'postcss';  // Or similar CSS parser

interface ParsedStylesheet {
  rules: CSSRule[];
  selectors: Map<string, CSSStyleDeclaration>;
  mediaQueries: MediaQueryRule[];
  keyframes: KeyframeRule[];
  variables: Map<string, string>;  // CSS custom properties
}

interface CSSRule {
  selector: string;
  declarations: CSSDeclaration[];
  specificity: number;
  source: string;  // File path
  line: number;
}

interface CSSDeclaration {
  property: string;
  value: string;
  important: boolean;
}

class CSSParser {
  private postcss: typeof postcss;
  
  // Main parse
  async parse(cssContent: string, sourcePath: string): Promise<ParsedStylesheet>;
  parseMultiple(sheets: {content: string, path: string}[]): Promise<ParsedStylesheet[]>;
  
  // Rule extraction
  extractRules(ast: postcss.Root): CSSRule[];
  extractMediaQueries(ast: postcss.Root): MediaQueryRule[];
  extractKeyframes(ast: postcss.Root): KeyframeRule[];
  extractVariables(ast: postcss.Root): Map<string, string>;
  
  // Matching
  matchRulesToElement(
    element: Element, 
    stylesheets: ParsedStylesheet[]
  ): CSSStyleDeclaration;
  
  computeCascade(matchingRules: CSSRule[]): CSSStyleDeclaration;
  
  // URL extraction
  extractUrls(cssContent: string): string[];
  
  // Modification
  addRule(stylesheet: ParsedStylesheet, rule: CSSRule): void;
  removeRule(stylesheet: ParsedStylesheet, selector: string): void;
  updateDeclaration(
    stylesheet: ParsedStylesheet,
    selector: string,
    property: string,
    value: string
  ): void;
  
  // Serialization
  serialize(stylesheet: ParsedStylesheet): string;
  serializeToInlineStyles(styles: CSSStyleDeclaration): string;
}
```

### 5. Layer Builder

```typescript
// src/core/parser/LayerBuilder.ts

interface LayerTree {
  root: Layer;
  byId: Map<string, Layer>;
  byElement: WeakMap<HTMLElement, Layer>;
}

class LayerBuilder {
  private idCounter: number = 0;
  
  // Build from parsed document
  build(doc: ParsedDocument, stylesheets: ParsedStylesheet[]): LayerTree;
  
  // Element to layer conversion
  private elementToLayer(
    element: HTMLElement,
    parent: Layer | null,
    stylesheets: ParsedStylesheet[]
  ): Layer;
  
  // Detect layer type
  private detectLayerType(element: HTMLElement): LayerType;
  
  // Extract computed styles
  private extractComputedStyles(
    element: HTMLElement,
    stylesheets: ParsedStylesheet[]
  ): ComputedCSS;
  
  // Calculate initial transform
  private calculateTransform(element: HTMLElement): Transform;
  
  // Generate unique ID
  private generateId(): string;
  
  // Flatten tree to array
  flatten(tree: LayerTree): Layer[];
  
  // Search
  findById(tree: LayerTree, id: string): Layer | null;
  findByElement(tree: LayerTree, element: HTMLElement): Layer | null;
}
```

---

## Drag & Drop Implementation

```typescript
// src/components/FileDropZone.ts

class FileDropZone {
  private element: HTMLElement;
  private onFilesDropped: (files: FileEntry[]) => void;
  private isDragging: boolean = false;
  
  mount(container: HTMLElement): void {
    this.element = document.createElement('div');
    this.element.className = 'file-drop-zone';
    
    // Event listeners
    container.addEventListener('dragenter', this.handleDragEnter);
    container.addEventListener('dragover', this.handleDragOver);
    container.addEventListener('dragleave', this.handleDragLeave);
    container.addEventListener('drop', this.handleDrop);
    
    container.appendChild(this.element);
  }
  
  private handleDragEnter = (e: DragEvent): void => {
    e.preventDefault();
    this.isDragging = true;
    this.element.classList.add('drag-over');
  };
  
  private handleDragOver = (e: DragEvent): void => {
    e.preventDefault();
    e.dataTransfer!.dropEffect = 'copy';
  };
  
  private handleDrop = async (e: DragEvent): Promise<void> => {
    e.preventDefault();
    this.isDragging = false;
    this.element.classList.remove('drag-over');
    
    const reader = new FileSystemReader();
    const files = await reader.readDataTransfer(e.dataTransfer!);
    
    this.onFilesDropped(files);
  };
}
```

```css
/* File Drop Zone Styles */
.file-drop-zone {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 102, 255, 0.1);
  border: 4px dashed #0066FF;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s;
  z-index: 1000;
}

.file-drop-zone.drag-over {
  opacity: 1;
}

.file-drop-zone::after {
  content: 'Drop folder or files here';
  font-size: 24px;
  color: #0066FF;
  font-weight: 500;
}
```

---

## File System Access API

```typescript
// Alternative entry point using modern File System Access API

class FileSystemAccessAPI {
  // Show directory picker
  async openDirectory(): Promise<FileEntry[]> {
    try {
      const handle = await window.showDirectoryPicker();
      const reader = new FileSystemReader();
      return await reader.readDirectoryHandle(handle);
    } catch (err) {
      console.log('User cancelled directory picker');
      return [];
    }
  }
  
  // Show file picker (for single files)
  async openFile(): Promise<FileEntry | null> {
    try {
      const [handle] = await window.showOpenFilePicker({
        types: [{
          description: 'HTML Files',
          accept: { 'text/html': ['.html', '.htm'] }
        }]
      });
      
      const file = await handle.getFile();
      return {
        name: file.name,
        path: file.name,
        fullPath: file.name,
        type: 'file',
        size: file.size,
        lastModified: file.lastModified,
        content: file
      };
    } catch (err) {
      return null;
    }
  }
  
  // Save project back to disk
  async saveProject(project: Project): Promise<void> {
    const handle = await window.showSaveFilePicker({
      suggestedName: `${project.name}.json`,
      types: [{
        description: 'WebBuilder Project',
        accept: { 'application/json': ['.json'] }
      }]
    });
    
    const writable = await handle.createWritable();
    const data = JSON.stringify(project, null, 2);
    await writable.write(data);
    await writable.close();
  }
}
```

---

## Processing Flow

```typescript
// Main import orchestration

class ProjectImporter {
  private fileReader: FileSystemReader;
  private assetExtractor: AssetExtractor;
  private htmlParser: HTMLParser;
  private cssParser: CSSParser;
  private layerBuilder: LayerBuilder;
  
  async import(files: FileEntry[]): Promise<Project> {
    // 1. Separate by type
    const htmlFiles = files.filter(f => f.name.endsWith('.html'));
    const cssFiles = files.filter(f => f.name.endsWith('.css'));
    const jsFiles = files.filter(f => f.name.endsWith('.js'));
    const assetFiles = files.filter(f => this.isAsset(f.name));
    
    // 2. Extract assets first
    const assets = await this.assetExtractor.extract(assetFiles);
    
    // 3. Find main HTML file
    const mainHtml = this.findMainHtml(htmlFiles);
    const htmlContent = await mainHtml.content!.text();
    
    // 4. Parse HTML
    const parsedDoc = await this.htmlParser.parse(htmlContent, {
      baseUrl: mainHtml.path,
      rewriteAssetUrls: true,
      extractInlineStyles: true,
      preserveScripts: true
    });
    
    // 5. Parse external CSS
    const parsedStylesheets: ParsedStylesheet[] = [];
    for (const cssRef of parsedDoc.stylesheets) {
      const cssFile = files.find(f => f.path === cssRef.href || f.name === cssRef.href);
      if (cssFile) {
        const cssContent = await cssFile.content!.text();
        const parsed = await this.cssParser.parse(cssContent, cssFile.path);
        parsedStylesheets.push(parsed);
      }
    }
    
    // 6. Parse inline CSS
    const inlineStyles = this.htmlParser.extractInlineStyles(parsedDoc.html);
    
    // 7. Build layer tree
    const layerTree = this.layerBuilder.build(parsedDoc, parsedStylesheets);
    
    // 8. Create project
    return {
      id: generateUUID(),
      name: this.extractProjectName(mainHtml.name),
      createdAt: new Date(),
      modifiedAt: new Date(),
      rootLayer: layerTree.root,
      assets: Array.from(assets.images.values()),
      viewport: {
        zoom: 1,
        panX: 0,
        panY: 0
      },
      html: parsedDoc,
      stylesheets: parsedStylesheets
    };
  }
  
  private findMainHtml(files: FileEntry[]): FileEntry {
    // Priority: index.html > any .html file
    return files.find(f => f.name === 'index.html') || files[0];
  }
  
  private isAsset(fileName: string): boolean {
    const ext = fileName.split('.').pop()?.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'svg', 'webp', 'woff', 'woff2', 'ttf', 'otf'].includes(ext || '');
  }
  
  private extractProjectName(fileName: string): string {
    return fileName.replace(/\.html?$/, '');
  }
}
```

---

## Error Handling

```typescript
// Error types

enum ImportErrorType {
  NO_HTML_FOUND = 'no_html_found',
  INVALID_HTML = 'invalid_html',
  CSS_PARSE_ERROR = 'css_parse_error',
  ASSET_LOAD_ERROR = 'asset_load_error',
  UNSUPPORTED_FORMAT = 'unsupported_format',
  PERMISSION_DENIED = 'permission_denied'
}

interface ImportError {
  type: ImportErrorType;
  message: string;
  file?: string;
  recoverable: boolean;
}

class ImportErrorHandler {
  private errors: ImportError[] = [];
  
  addError(error: ImportError): void {
    this.errors.push(error);
    console.error(`[Import Error] ${error.type}: ${error.message}`);
  }
  
  hasErrors(): boolean {
    return this.errors.length > 0;
  }
  
  getErrors(): ImportError[] {
    return this.errors;
  }
  
  getRecoverableErrors(): ImportError[] {
    return this.errors.filter(e => e.recoverable);
  }
  
  clear(): void {
    this.errors = [];
  }
}
```

---

## Performance Considerations

| Scenario | Strategy |
|----------|----------|
| Large files (>10MB) | Stream processing, chunked reading |
| Many files (>100) | Web Workers for parallel processing |
| Deep directories | Async recursion with depth limit |
| Binary assets | Lazy blob URL generation |
| CSS parsing | Incremental parsing with yield points |

---

## Browser Compatibility

```typescript
// Feature detection

const FileUploadCapabilities = {
  // File System Access API (Chrome 86+, Edge 86+)
  fileSystemAccess: 'showDirectoryPicker' in window,
  
  // DataTransferItem (all modern browsers)
  dataTransferItem: true,
  
  // Directory upload via webkitdirectory (all modern)
  webkitDirectory: true,
  
  // Blob URLs (all modern browsers)
  blobUrls: true,
  
  // Drag and drop (all modern browsers)
  dragAndDrop: true
};

function getBestUploadMethod(): 'file-system-access' | 'drag-drop' | 'file-input' {
  if (FileUploadCapabilities.fileSystemAccess) {
    return 'file-system-access';
  }
  if (FileUploadCapabilities.dragAndDrop) {
    return 'drag-drop';
  }
  return 'file-input';
}
```

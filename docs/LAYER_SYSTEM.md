# Layer System Technical Specification

## Overview
The Layer System manages the hierarchical representation of the website structure. It provides a tree-based view that mirrors the DOM, with additional metadata for editing (visibility, locking, naming, etc.).

---

## Layer Tree Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         LAYER TREE EXAMPLE                               │
└─────────────────────────────────────────────────────────────────────────┘

Project: "My Landing Page"
│
├─ [Layer: root] "HTML Document"
│  │  type: ROOT
│  │  domPath: "html"
│  │  visible: true
│  │  locked: false
│  │
│  ├─ [Layer: head-1] "Head"
│  │  │  type: CONTAINER
│  │  │  domPath: "html > head"
│  │  │  visible: true (hidden in canvas, shown in layers panel)
│  │  │  locked: true
│  │  │
│  │  └─ [Layer: meta-1] "Meta Tags"
│  │     type: COMPONENT
│  │     collapsed: true
│  │
│  └─ [Layer: body-1] "Body"
│     │  type: CONTAINER
│     │  domPath: "html > body"
│     │  visible: true
│     │  locked: false
│     │
│     ├─ [Layer: nav-1] "Navigation Bar" ◄── SELECTED
│     │  │  type: CONTAINER
│     │  │  domPath: "html > body > nav.navbar"
│     │  │  visible: true
│     │  │  locked: false
│     │  │  selected: true
│     │  │
│     │  ├─ [Layer: div-2] "Logo Container"
│     │  │  └─ [Layer: img-1] "Logo Image"
│     │  │     type: IMAGE
│     │  │     visible: true
│     │  │     locked: false
│     │  │
│     │  └─ [Layer: ul-1] "Nav Links"
│     │     ├─ [Layer: li-1] "Home Link"
│     │     ├─ [Layer: li-2] "About Link"
│     │     └─ [Layer: li-3] "Contact Link"
│     │
│     ├─ [Layer: section-1] "Hero Section"
│     │  │  type: CONTAINER
│     │  │  visible: true
│     │  │  locked: false
│     │  │  collapsed: false
│     │  │
│     │  ├─ [Layer: h1-1] "Hero Heading" ◄── SELECTED
│     │  │  type: TEXT
│     │  │  selected: true
│     │  │  visible: true
│     │  │  textContent: "Welcome!"
│     │  │
│     │  ├─ [Layer: p-1] "Hero Subtext"
│     │  │  type: TEXT
│     │  │  visible: true
│     │  │  locked: false
│     │  │
│     │  └─ [Layer: button-1] "CTA Button"
│     │     type: CONTAINER
│     │     visible: true
│     │     locked: false
│     │
│     └─ [Layer: footer-1] "Footer"
│        type: CONTAINER
│        visible: false  ◄── HIDDEN (eye icon crossed)
│        locked: false


VISUAL REPRESENTATION IN UI:
────────────────────────────

Layers                                      │  Visibility  │  Lock  │
────────────────────────────────────────────┼──────────────┼────────┤
🗀 HTML Document                             │      👁      │   🔓   │
  ▶ 🗀 Head                                   │      👁      │   🔒   │
  ▼ 🗀 Body                                   │      👁      │   🔓   │
    ▼ ● Navigation Bar              [SELECTED]│      👁      │   🔓   │
        🗀 Logo Container                     │      👁      │   🔓   │
          🖼 Logo Image                       │      👁      │   🔓   │
        🗀 Nav Links                          │      👁      │   🔓   │
          ─ Home Link                         │      👁      │   🔓   │
          ─ About Link                        │      👁      │   🔓   │
          ─ Contact Link                      │      👁      │   🔓   │
    ▼ 🗀 Hero Section                         │      👁      │   🔓   │
      ● Hero Heading                [SELECTED]│      👁      │   🔓   │
      ─ Hero Subtext                          │      👁      │   🔓   │
      🗀 CTA Button                           │      👁      │   🔓   │
    🗀 Footer                         [HIDDEN] │      🚫      │   🔓   │
```

---

## Core Types

```typescript
// src/types/layer.ts

enum LayerType {
  ROOT = 'root',              // Document root
  CONTAINER = 'container',    // div, section, article, etc.
  TEXT = 'text',              // p, h1-h6, span, a
  IMAGE = 'image',            // img, picture
  INPUT = 'input',            // input, textarea, select
  BUTTON = 'button',          // button, input[type="button"]
  LIST = 'list',              // ul, ol, dl
  LIST_ITEM = 'list-item',    // li, dt, dd
  TABLE = 'table',            // table
  COMPONENT = 'component',    // Custom web components
  SVG = 'svg',                // SVG elements
  CANVAS = 'canvas',          // Canvas elements
  VIDEO = 'video',            // Video elements
  AUDIO = 'audio',            // Audio elements
  IFRAME = 'iframe',          // Embedded content
  SCRIPT = 'script',          // Scripts (hidden by default)
  STYLE = 'style',            // Style blocks (hidden by default)
  COMMENT = 'comment',        // HTML comments
}

interface Layer {
  // Identity
  id: string;                    // Unique identifier
  name: string;                  // User-editable display name
  type: LayerType;               // Layer classification
  
  // DOM linkage
  element: HTMLElement;          // Reference to actual DOM element
  domPath: string;               // CSS selector path
  tagName: string;               // HTML tag name
  
  // Hierarchy
  parent: Layer | null;          // Parent layer
  children: Layer[];             // Child layers
  index: number;                 // Position among siblings
  depth: number;                 // Nesting depth (0 = root)
  
  // Visual state
  visible: boolean;              // Show/hide in canvas
  locked: boolean;               // Prevent editing
  collapsed: boolean;            // Collapse children in panel
  selected: boolean;             // Currently selected
  
  // Content properties (type-specific)
  content?: LayerContent;
  
  // Computed properties (cached)
  bounds: Rect;                  // Position and dimensions
  computedStyles: ComputedCSS;   // Resolved CSS values
  transform: Transform;          // Visual transform
  
  // Metadata
  metadata: LayerMetadata;
}

interface LayerContent {
  // For TEXT layers
  textContent?: string;
  
  // For IMAGE layers
  src?: string;
  alt?: string;
  naturalWidth?: number;
  naturalHeight?: number;
  
  // For LINK layers
  href?: string;
  target?: string;
  
  // For INPUT layers
  inputType?: string;
  placeholder?: string;
  value?: string;
}

interface LayerMetadata {
  createdAt: Date;
  modifiedAt: Date;
  importedFrom: string;          // Original file path
  isAutoNamed: boolean;          // Name was auto-generated
  customData: Record<string, any>;
}

interface ComputedCSS {
  display: string;
  position: string;
  width: string;
  height: string;
  padding: string;
  margin: string;
  backgroundColor: string;
  color: string;
  fontSize: string;
  fontFamily: string;
  border: string;
  // ... all computed styles
}
```

---

## Layer Manager

```typescript
// src/core/layers/LayerManager.ts

class LayerManager {
  private root: Layer;
  private byId: Map<string, Layer>;
  private byElement: WeakMap<HTMLElement, Layer>;
  private selectedIds: Set<string>;
  private subscribers: Set<(event: LayerEvent) => void>;
  
  // Initialization
  constructor(rootElement: HTMLElement);
  buildTree(rootElement: HTMLElement): Layer;
  
  // Layer CRUD
  createLayer(
    element: HTMLElement,
    parent: Layer,
    index?: number
  ): Layer;
  
  deleteLayer(id: string): boolean;
  deleteLayers(ids: string[]): string[];  // Returns successfully deleted
  
  moveLayer(
    id: string,
    newParentId: string,
    newIndex: number
  ): boolean;
  
  duplicateLayer(id: string): Layer | null;
  
  // Naming
  setLayerName(id: string, name: string): void;
  generateLayerName(layer: Layer): string;
  autoRename(layer: Layer): void;
  
  // Visibility
  setVisible(id: string, visible: boolean): void;
  toggleVisibility(id: string): void;
  showAll(): void;
  hideAll(): void;
  showOnly(ids: string[]): void;
  
  // Locking
  setLocked(id: string, locked: boolean): void;
  toggleLocked(id: string): void;
  lockAll(): void;
  unlockAll(): void;
  unlockSelected(): void;
  
  // Collapsing
  setCollapsed(id: string, collapsed: boolean): void;
  toggleCollapsed(id: string): void;
  expandAll(): void;
  collapseAll(): void;
  expandToLayer(id: string): void;
  
  // Selection
  select(id: string, mode: 'replace' | 'add' | 'toggle' = 'replace'): void;
  deselect(id: string): void;
  deselectAll(): void;
  getSelected(): Layer[];
  isSelected(id: string): boolean;
  
  // Queries
  getById(id: string): Layer | null;
  getByElement(element: HTMLElement): Layer | null;
  findByName(name: string): Layer[];
  findByType(type: LayerType): Layer[];
  findVisible(): Layer[];
  findLocked(): Layer[];
  findAtPoint(x: number, y: number): Layer[];  // Hit testing
  
  // Traversal
  traverse(callback: (layer: Layer) => void | 'stop'): void;
  traverseDepthFirst(callback: (layer: Layer) => void): void;
  traverseBreadthFirst(callback: (layer: Layer) => void): void;
  
  // Flattening
  flatten(): Layer[];
  flattenVisible(): Layer[];
  flattenSelectable(): Layer[];
  
  // Hierarchy helpers
  getAncestors(id: string): Layer[];
  getDescendants(id: string): Layer[];
  getSiblings(id: string): Layer[];
  getNextSibling(id: string): Layer | null;
  getPreviousSibling(id: string): Layer | null;
  canMoveTo(sourceId: string, targetId: string): boolean;
  
  // Synchronization
  syncFromDOM(): void;           // DOM → Layer tree
  syncToDOM(): void;             // Layer tree → DOM
  
  // Events
  subscribe(callback: (event: LayerEvent) => void): () => void;
  notify(event: LayerEvent): void;
  
  // Serialization
  serialize(): SerializedLayerTree;
  deserialize(data: SerializedLayerTree): void;
}

// Layer events
interface LayerEvent {
  type: 'created' | 'deleted' | 'moved' | 'modified' | 'selected' | 'visibility' | 'locked';
  layerId: string;
  data?: any;
}
```

---

## Layer Naming Convention

```typescript
// src/core/layers/LayerNaming.ts

class LayerNaming {
  // Auto-generate descriptive names
  static generateName(layer: Layer): string {
    const { type, tagName, element } = layer;
    
    // Use semantic clues
    const semanticName = this.getSemanticName(element);
    if (semanticName) return semanticName;
    
    // Use class names
    const className = this.getClassName(element);
    if (className) return `${className} ${this.getTypeLabel(type)}`;
    
    // Use ID
    const id = element.id;
    if (id) return `#${id}`;
    
    // Use content hint
    const contentHint = this.getContentHint(layer);
    if (contentHint) return contentHint;
    
    // Fallback to type + index
    return `${this.getTypeLabel(type)} ${this.getTypeIndex(layer)}`;
  }
  
  private static getSemanticName(element: HTMLElement): string | null {
    const role = element.getAttribute('role');
    if (role) return role.charAt(0).toUpperCase() + role.slice(1);
    
    const ariaLabel = element.getAttribute('aria-label');
    if (ariaLabel) return ariaLabel;
    
    // Landmark elements
    const landmarks: Record<string, string> = {
      'HEADER': 'Header',
      'NAV': 'Navigation',
      'MAIN': 'Main Content',
      'ASIDE': 'Sidebar',
      'FOOTER': 'Footer',
      'ARTICLE': 'Article',
      'SECTION': 'Section'
    };
    
    return landmarks[element.tagName] || null;
  }
  
  private static getClassName(element: HTMLElement): string | null {
    const classes = element.className;
    if (!classes || typeof classes !== 'string') return null;
    
    // Pick the most descriptive class
    const classList = classes.split(' ').filter(c => c.length > 2);
    if (classList.length === 0) return null;
    
    // Convert kebab-case to Title Case
    return classList[0]
      .split('-')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }
  
  private static getContentHint(layer: Layer): string | null {
    if (layer.type === LayerType.TEXT) {
      const text = layer.content?.textContent?.slice(0, 20) || '';
      if (text) return `"${text}${text.length >= 20 ? '...' : ''}"`;
    }
    
    if (layer.type === LayerType.IMAGE) {
      const src = layer.content?.src || '';
      const fileName = src.split('/').pop();
      if (fileName) return `Image: ${fileName}`;
    }
    
    return null;
  }
  
  private static getTypeLabel(type: LayerType): string {
    const labels: Record<LayerType, string> = {
      [LayerType.ROOT]: 'Document',
      [LayerType.CONTAINER]: 'Container',
      [LayerType.TEXT]: 'Text',
      [LayerType.IMAGE]: 'Image',
      [LayerType.INPUT]: 'Input',
      [LayerType.BUTTON]: 'Button',
      [LayerType.LIST]: 'List',
      [LayerType.LIST_ITEM]: 'List Item',
      [LayerType.TABLE]: 'Table',
      [LayerType.COMPONENT]: 'Component',
      [LayerType.SVG]: 'SVG',
      [LayerType.CANVAS]: 'Canvas',
      [LayerType.VIDEO]: 'Video',
      [LayerType.AUDIO]: 'Audio',
      [LayerType.IFRAME]: 'Embed',
      [LayerType.SCRIPT]: 'Script',
      [LayerType.STYLE]: 'Style',
      [LayerType.COMMENT]: 'Comment'
    };
    
    return labels[type] || 'Element';
  }
}
```

---

## Layer Panel UI Component

```typescript
// src/components/layers/LayerPanel.ts

interface LayerPanelProps {
  layerManager: LayerManager;
  onLayerSelect: (layer: Layer) => void;
  onLayerDoubleClick: (layer: Layer) => void;
  onLayerContextMenu: (layer: Layer, event: MouseEvent) => void;
}

class LayerPanel {
  private element: HTMLElement;
  private layerManager: LayerManager;
  private expandedLayers: Set<string>;
  private filter: string;
  
  mount(container: HTMLElement): void {
    this.element = document.createElement('div');
    this.element.className = 'layer-panel';
    
    this.render();
    container.appendChild(this.element);
    
    // Subscribe to layer changes
    this.layerManager.subscribe(this.handleLayerEvent);
  }
  
  private render(): void {
    const root = this.layerManager.getRoot();
    
    this.element.innerHTML = `
      <div class="layer-panel-header">
        <span>Layers</span>
        <div class="layer-panel-actions">
          <button data-action="expand-all">⌄⌄</button>
          <button data-action="collapse-all">⌃⌃</button>
        </div>
      </div>
      <div class="layer-tree">
        ${this.renderLayer(root, 0)}
      </div>
    `;
    
    this.attachEventListeners();
  }
  
  private renderLayer(layer: Layer, depth: number): string {
    const isExpanded = !layer.collapsed;
    const hasChildren = layer.children.length > 0;
    const indent = depth * 16;
    
    const toggleIcon = hasChildren 
      ? (isExpanded ? '▼' : '▶') 
      : '•';
    
    const typeIcon = this.getTypeIcon(layer.type);
    const visibilityIcon = layer.visible ? '👁' : '🚫';
    const lockIcon = layer.locked ? '🔒' : '🔓';
    const selectedClass = layer.selected ? 'selected' : '';
    
    return `
      <div class="layer-item ${selectedClass}" 
           data-layer-id="${layer.id}"
           style="padding-left: ${indent}px">
        <span class="layer-toggle">${toggleIcon}</span>
        <span class="layer-icon">${typeIcon}</span>
        <span class="layer-name">${this.escapeHtml(layer.name)}</span>
        <span class="layer-visibility" data-action="toggle-visibility">${visibilityIcon}</span>
        <span class="layer-lock" data-action="toggle-lock">${lockIcon}</span>
      </div>
      ${isExpanded ? layer.children.map(c => this.renderLayer(c, depth + 1)).join('') : ''}
    `;
  }
  
  private getTypeIcon(type: LayerType): string {
    const icons: Record<LayerType, string> = {
      [LayerType.ROOT]: '📄',
      [LayerType.CONTAINER]: '🗀',
      [LayerType.TEXT]: '📝',
      [LayerType.IMAGE]: '🖼',
      [LayerType.INPUT]: '⌨',
      [LayerType.BUTTON]: '🔘',
      [LayerType.LIST]: '☰',
      [LayerType.LIST_ITEM]: '–',
      [LayerType.TABLE]: '⊞',
      [LayerType.COMPONENT]: '⚙',
      [LayerType.SVG]: '⬡',
      [LayerType.CANVAS]: '▣',
      [LayerType.VIDEO]: '▶',
      [LayerType.AUDIO]: '♪',
      [LayerType.IFRAME]: '🌐',
      [LayerType.SCRIPT]: '📜',
      [LayerType.STYLE]: '🎨',
      [LayerType.COMMENT]: '💬'
    };
    return icons[type] || '•';
  }
  
  private attachEventListeners(): void {
    this.element.addEventListener('click', this.handleClick);
    this.element.addEventListener('dblclick', this.handleDoubleClick);
    this.element.addEventListener('contextmenu', this.handleContextMenu);
  }
  
  private handleClick = (e: MouseEvent) => {
    const target = e.target as HTMLElement;
    const layerItem = target.closest('[data-layer-id]') as HTMLElement;
    if (!layerItem) return;
    
    const layerId = layerItem.dataset.layerId!;
    const action = target.dataset.action;
    
    if (action === 'toggle-visibility') {
      this.layerManager.toggleVisibility(layerId);
    } else if (action === 'toggle-lock') {
      this.layerManager.toggleLocked(layerId);
    } else if (target.classList.contains('layer-toggle')) {
      this.layerManager.toggleCollapsed(layerId);
    } else {
      // Select layer
      const mode: 'replace' | 'add' | 'toggle' = e.shiftKey 
        ? 'add' 
        : e.metaKey || e.ctrlKey 
          ? 'toggle' 
          : 'replace';
      this.layerManager.select(layerId, mode);
    }
  };
}
```

```css
/* Layer Panel Styles */
.layer-panel {
  width: 260px;
  background: #2C2C2C;
  color: #E0E0E0;
  font-size: 12px;
  user-select: none;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.layer-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid #404040;
  font-weight: 500;
}

.layer-panel-actions button {
  background: transparent;
  border: none;
  color: #999;
  cursor: pointer;
  padding: 2px 6px;
  font-size: 10px;
}

.layer-panel-actions button:hover {
  color: #fff;
}

.layer-tree {
  flex: 1;
  overflow-y: auto;
  overflow-x: hidden;
}

.layer-item {
  display: flex;
  align-items: center;
  padding: 4px 8px;
  cursor: pointer;
  height: 24px;
  border-bottom: 1px solid transparent;
}

.layer-item:hover {
  background: #3C3C3C;
}

.layer-item.selected {
  background: #0066FF;
}

.layer-item.selected:hover {
  background: #1a75FF;
}

.layer-toggle {
  width: 16px;
  text-align: center;
  font-size: 8px;
  color: #888;
  cursor: pointer;
}

.layer-icon {
  width: 16px;
  text-align: center;
  margin-right: 4px;
}

.layer-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.layer-visibility,
.layer-lock {
  width: 20px;
  text-align: center;
  cursor: pointer;
  opacity: 0.6;
}

.layer-visibility:hover,
.layer-lock:hover {
  opacity: 1;
}

.layer-item:not(:hover) .layer-visibility:not(.hidden),
.layer-item:not(:hover) .layer-lock:not(.locked) {
  opacity: 0;
}
```

---

## DOM Synchronization

```typescript
// src/core/sync/LayerDOMSync.ts

class LayerDOMSync {
  private layerManager: LayerManager;
  private observer: MutationObserver;
  private syncQueue: Set<string> = new Set();
  private isSyncing: boolean = false;
  
  constructor(layerManager: LayerManager) {
    this.layerManager = layerManager;
    this.setupMutationObserver();
  }
  
  // Watch for DOM changes
  private setupMutationObserver(): void {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach(mutation => {
        switch (mutation.type) {
          case 'childList':
            this.handleChildListMutation(mutation);
            break;
          case 'attributes':
            this.handleAttributeMutation(mutation);
            break;
          case 'characterData':
            this.handleCharacterDataMutation(mutation);
            break;
        }
      });
    });
  }
  
  private handleChildListMutation(mutation: MutationRecord): void {
    // Added nodes
    mutation.addedNodes.forEach(node => {
      if (node instanceof HTMLElement) {
        this.syncQueue.add('create:' + this.getElementPath(node));
      }
    });
    
    // Removed nodes
    mutation.removedNodes.forEach(node => {
      if (node instanceof HTMLElement) {
        const layer = this.layerManager.getByElement(node);
        if (layer) {
          this.syncQueue.add('delete:' + layer.id);
        }
      }
    });
    
    this.scheduleSync();
  }
  
  private handleAttributeMutation(mutation: MutationRecord): void {
    const element = mutation.target as HTMLElement;
    const layer = this.layerManager.getByElement(element);
    if (!layer) return;
    
    // Track specific attributes
    switch (mutation.attributeName) {
      case 'class':
        this.syncQueue.add(`update:${layer.id}:class`);
        break;
      case 'style':
        this.syncQueue.add(`update:${layer.id}:style`);
        break;
      case 'id':
        this.syncQueue.add(`update:${layer.id}:id`);
        break;
    }
    
    this.scheduleSync();
  }
  
  private scheduleSync(): void {
    if (this.isSyncing) return;
    
    requestAnimationFrame(() => {
      this.flushSyncQueue();
    });
  }
  
  private flushSyncQueue(): void {
    this.isSyncing = true;
    
    this.syncQueue.forEach(operation => {
      const [type, id, detail] = operation.split(':');
      
      switch (type) {
        case 'create':
          this.syncCreateLayer(id);
          break;
        case 'delete':
          this.syncDeleteLayer(id);
          break;
        case 'update':
          this.syncUpdateLayer(id, detail);
          break;
      }
    });
    
    this.syncQueue.clear();
    this.isSyncing = false;
  }
  
  // Apply layer changes to DOM
  applyToDOM(layer: Layer): void {
    const element = layer.element;
    
    // Update visibility
    element.style.display = layer.visible ? '' : 'none';
    
    // Update transform (if modified)
    if (layer.transform) {
      this.applyTransform(element, layer.transform);
    }
    
    // Update content (for text layers)
    if (layer.type === LayerType.TEXT && layer.content?.textContent) {
      element.textContent = layer.content.textContent;
    }
    
    // Update attributes
    if (layer.content?.src) {
      (element as HTMLImageElement).src = layer.content.src;
    }
  }
  
  private applyTransform(element: HTMLElement, transform: Transform): void {
    const { x, y, width, height, rotation, scaleX, scaleY } = transform;
    
    element.style.transform = `
      translate(${x}px, ${y}px)
      rotate(${rotation}deg)
      scale(${scaleX}, ${scaleY})
    `;
    
    element.style.width = `${width}px`;
    element.style.height = `${height}px`;
  }
  
  private getElementPath(element: HTMLElement): string {
    // Generate unique path for element
    const path: string[] = [];
    let current: Element | null = element;
    
    while (current) {
      let selector = current.tagName.toLowerCase();
      if (current.id) {
        selector += `#${current.id}`;
      } else if (current.className) {
        selector += `.${current.className.split(' ')[0]}`;
      }
      path.unshift(selector);
      current = current.parentElement;
    }
    
    return path.join(' > ');
  }
}
```

---

## Search & Filter

```typescript
// src/core/layers/LayerSearch.ts

interface SearchOptions {
  query: string;
  types?: LayerType[];
  visibleOnly?: boolean;
  lockedOnly?: boolean;
  caseSensitive?: boolean;
  exactMatch?: boolean;
}

class LayerSearch {
  private layerManager: LayerManager;
  
  search(options: SearchOptions): Layer[] {
    const { query, types, visibleOnly, lockedOnly, caseSensitive, exactMatch } = options;
    
    const allLayers = this.layerManager.flatten();
    
    return allLayers.filter(layer => {
      // Type filter
      if (types && !types.includes(layer.type)) {
        return false;
      }
      
      // Visibility filter
      if (visibleOnly && !layer.visible) {
        return false;
      }
      
      // Lock filter
      if (lockedOnly && !layer.locked) {
        return false;
      }
      
      // Text search
      const searchIn = [
        layer.name,
        layer.domPath,
        layer.content?.textContent || ''
      ].join(' ');
      
      const compare = caseSensitive 
        ? searchIn 
        : searchIn.toLowerCase();
      const compareQuery = caseSensitive 
        ? query 
        : query.toLowerCase();
      
      if (exactMatch) {
        return compare === compareQuery;
      }
      
      return compare.includes(compareQuery);
    });
  }
  
  // Fuzzy search with scoring
  fuzzySearch(query: string): Array<{ layer: Layer; score: number }> {
    const results: Array<{ layer: Layer; score: number }> = [];
    const allLayers = this.layerManager.flatten();
    
    allLayers.forEach(layer => {
      const score = this.calculateFuzzyScore(query, layer);
      if (score > 0) {
        results.push({ layer, score });
      }
    });
    
    return results.sort((a, b) => b.score - a.score);
  }
  
  private calculateFuzzyScore(query: string, layer: Layer): number {
    let score = 0;
    const queryLower = query.toLowerCase();
    
    // Exact name match
    if (layer.name.toLowerCase() === queryLower) {
      score += 100;
    } else if (layer.name.toLowerCase().includes(queryLower)) {
      score += 50;
    }
    
    // DOM path match
    if (layer.domPath.toLowerCase().includes(queryLower)) {
      score += 25;
    }
    
    // Content match (for text layers)
    if (layer.content?.textContent?.toLowerCase().includes(queryLower)) {
      score += 10;
    }
    
    // Class names match
    const classNames = layer.element.className || '';
    if (classNames.toLowerCase().includes(queryLower)) {
      score += 20;
    }
    
    return score;
  }
}
```

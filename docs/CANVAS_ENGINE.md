# Canvas Engine Technical Specification

## Overview
The Canvas Engine is the heart of the visual editor, providing an infinite canvas with pan/zoom capabilities, hybrid rendering (iframe + canvas overlay), and selection/transform interactions.

---

## Core Components

### 1. Viewport Manager

```typescript
// src/core/renderer/ViewportManager.ts

interface ViewportState {
  zoom: number;           // 0.1 to 5.0 (10% to 500%)
  panX: number;          // Pan offset X in screen pixels
  panY: number;          // Pan offset Y in screen pixels
  width: number;         // Viewport width
  height: number;        // Viewport height
}

class ViewportManager {
  private state: ViewportState;
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  
  // Coordinate transformations
  screenToWorld(point: Point): Point;
  worldToScreen(point: Point): Point;
  screenToCanvas(point: Point): Point;
  
  // View operations
  zoom(factor: number, center: Point): void;
  pan(deltaX: number, deltaY: number): void;
  fitToContent(): void;
  resetView(): void;
  
  // Rendering
  render(): void;
  clear(): void;
}
```

### 2. Canvas Overlay Renderer

```typescript
// src/core/renderer/CanvasOverlay.ts

interface OverlayElement {
  id: string;
  type: 'selection' | 'handle' | 'guide' | 'hover' | 'marquee';
  bounds: Rect;
  style: OverlayStyle;
  data?: any;
}

class CanvasOverlay {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private elements: Map<string, OverlayElement>;
  private dirtyRegions: Rect[];
  
  // Element management
  addElement(element: OverlayElement): void;
  removeElement(id: string): void;
  updateElement(id: string, updates: Partial<OverlayElement>): void;
  
  // Rendering
  render(): void;
  renderElement(element: OverlayElement): void;
  
  // Dirty region tracking for performance
  markDirty(region: Rect): void;
  isDirty(region: Rect): boolean;
  
  // Drawing primitives
  drawSelectionBox(bounds: Rect, options: SelectionOptions): void;
  drawTransformHandles(bounds: Rect, handles: HandleType[]): void;
  drawGuideLine(start: Point, end: Point, type: 'horizontal' | 'vertical'): void;
  drawHoverHighlight(bounds: Rect): void;
  drawMarquee(start: Point, end: Point): void;
}
```

### 3. Iframe Manager

```typescript
// src/core/renderer/IframeManager.ts

interface IframeConfig {
  sandbox: string[];
  allowScripts: boolean;
  allowSameOrigin: boolean;
  csp: string;
}

class IframeManager {
  private iframe: HTMLIFrameElement;
  private container: HTMLElement;
  private contentDocument: Document | null;
  
  // Lifecycle
  mount(container: HTMLElement): void;
  unmount(): void;
  reload(): void;
  
  // Content
  loadHTML(html: string, baseUrl?: string): Promise<void>;
  loadFromFiles(files: FileSystemEntry[]): Promise<void>;
  
  // Access
  getDocument(): Document | null;
  getWindow(): Window | null;
  querySelector(selector: string): Element | null;
  querySelectorAll(selector: string): NodeListOf<Element>;
  
  // Coordination with canvas
  getElementBounds(element: Element): Rect;
  elementFromPoint(x: number, y: number): Element | null;
  
  // Events (forwarded to editor)
  onElementClick(callback: (element: Element, event: MouseEvent) => void): void;
  onElementHover(callback: (element: Element | null) => void): void;
}
```

---

## Coordinate Systems

```
┌────────────────────────────────────────────────────────────────────┐
│                        COORDINATE SYSTEMS                           │
└────────────────────────────────────────────────────────────────────┘


SCREEN COORDINATES (Pixels relative to viewport)
─────────────────────────────────────────────────
(0,0) ┌──────────────────────────────────────────┐
      │                                          │
      │    ╔══════════════════════════════╗      │
      │    ║                              ║      │
      │    ║     CANVAS COORDINATES       ║      │
      │    ║     (Scaled & Panned)        ║      │
      │    ║                              ║      │
      │    ║    (0,0) ┌─────────────┐     ║      │
      │    ║          │             │     ║      │
      │    ║          │   IFRAME    │     ║      │
      │    ║          │   CONTENT   │     ║      │
      │    ║          │             │     ║      │
      │    ║          │  Element at │     ║      │
      │    ║          │  (50, 100)  │     ║      │
      │    ║          │             │     ║      │
      │    ║          └─────────────┘     ║      │
      │    ║                              ║      │
      │    ╚══════════════════════════════╝      │
      │                                          │
      └──────────────────────────────────────────┘
                              (1920, 1080)


TRANSFORMATION MATH:
────────────────────

// Screen to Canvas (apply inverse transform)
canvasX = (screenX - panX) / zoom
canvasY = (screenY - panY) / zoom

// Canvas to Screen (apply transform)
screenX = canvasX * zoom + panX
screenY = canvasY * zoom + panY

// Canvas to Element (relative to iframe origin)
elementX = canvasX - iframeOffsetX
elementY = canvasY - iframeOffsetY


ZOOM LEVELS:
────────────
Min: 10%  (0.1)  - Overview mode
Default: 100% (1.0)
Max: 500% (5.0)  - Pixel-perfect editing
Step: 10% increments (with smooth transitions)

Presets:
- Fit: Zoom to fit entire page
- Fill: Zoom to fill viewport
- 100%: Actual size
- 200%: Detailed editing
```

---

## Rendering Pipeline

```typescript
// src/core/renderer/RenderLoop.ts

class RenderLoop {
  private isRunning: boolean = false;
  private rafId: number | null = null;
  private overlay: CanvasOverlay;
  private viewport: ViewportManager;
  
  start(): void {
    this.isRunning = true;
    this.tick();
  }
  
  stop(): void {
    this.isRunning = false;
    if (this.rafId) {
      cancelAnimationFrame(this.rafId);
    }
  }
  
  private tick(): void {
    if (!this.isRunning) return;
    
    // 1. Clear canvas
    this.overlay.clear();
    
    // 2. Draw static elements (grid, rulers)
    this.drawGrid();
    this.drawRulers();
    
    // 3. Draw dynamic elements (selections, handles)
    this.overlay.render();
    
    // 4. Schedule next frame
    this.rafId = requestAnimationFrame(() => this.tick());
  }
  
  // Optimized render for specific regions only
  renderRegion(region: Rect): void {
    this.overlay.markDirty(region);
  }
}
```

---

## Selection System

```typescript
// src/core/renderer/SelectionRenderer.ts

interface SelectionBox {
  id: string;
  bounds: Rect;
  rotation: number;
  isMulti: boolean;
  index: number;  // For multi-select stacking
}

class SelectionRenderer {
  private selections: Map<string, SelectionBox>;
  private overlay: CanvasOverlay;
  
  // Selection management
  select(elementIds: string[]): void;
  deselect(elementIds: string[]): void;
  clearSelection(): void;
  
  // Visual updates
  updateSelectionBounds(elementId: string, bounds: Rect): void;
  updateSelectionRotation(elementId: string, rotation: number): void;
  
  // Drawing
  render(): void;
  drawSelectionBox(box: SelectionBox): void;
  drawSelectionOutline(box: SelectionBox): void;
  drawMultiSelectIndicators(boxes: SelectionBox[]): void;
}

// Visual Design
const SELECTION_STYLE = {
  stroke: '#0066FF',        // Figma blue
  strokeWidth: 2,
  dashArray: [],            // Solid line
  
  // Multi-select
  multiStroke: '#0066FF',
  multiOpacity: 0.3,
  
  // Outline
  outlinePadding: 2,
  outlineStroke: 'rgba(0, 102, 255, 0.3)',
};
```

---

## Transform Controls

```typescript
// src/core/renderer/TransformControls.ts

enum HandleType {
  TOP_LEFT = 'nw',
  TOP_CENTER = 'n',
  TOP_RIGHT = 'ne',
  CENTER_LEFT = 'w',
  CENTER_RIGHT = 'e',
  BOTTOM_LEFT = 'sw',
  BOTTOM_CENTER = 's',
  BOTTOM_RIGHT = 'se',
  ROTATE = 'rotate'
}

interface TransformHandle {
  type: HandleType;
  position: Point;
  cursor: string;
  size: number;
}

class TransformControls {
  private targetBounds: Rect;
  private rotation: number;
  private handles: TransformHandle[];
  private activeHandle: HandleType | null;
  
  // Handle generation
  generateHandles(bounds: Rect, rotation: number): TransformHandle[];
  
  // Hit testing
  getHandleAtPoint(point: Point): HandleType | null;
  
  // Drawing
  render(): void;
  drawHandle(handle: TransformHandle, isActive: boolean): void;
  drawRotationIndicator(center: Point, radius: number): void;
  
  // Interaction
  onHandleDrag(handle: HandleType, delta: Point): Transform;
}

// Visual Design
const HANDLE_STYLE = {
  size: 8,
  fill: '#FFFFFF',
  stroke: '#0066FF',
  strokeWidth: 1,
  
  // Active state
  activeFill: '#0066FF',
  activeStroke: '#FFFFFF',
  
  // Rotation handle
  rotateLineLength: 20,
  rotateHandleSize: 12,
};
```

---

## Grid & Guides

```typescript
// src/core/renderer/GridRenderer.ts

interface GridConfig {
  type: 'none' | 'grid' | 'columns' | 'rows';
  size: number;
  color: string;
  opacity: number;
  snap: boolean;
}

class GridRenderer {
  private config: GridConfig;
  private viewport: ViewportManager;
  
  // Grid rendering
  render(): void;
  drawDotGrid(): void;
  drawLineGrid(): void;
  drawColumns(columns: number, gutter: number): void;
  drawRows(rows: number, gutter: number): void;
  
  // Smart guides (dynamic, based on element positions)
  drawSmartGuides(elements: Element[]): void;
  findAlignments(movingElement: Element, referenceElements: Element[]): GuideLine[];
  
  // Snapping
  snapPoint(point: Point, elements: Element[]): Point;
  snapBounds(bounds: Rect, elements: Element[]): Rect;
}

// Visual Design
const GRID_STYLE = {
  lineColor: 'rgba(0, 0, 0, 0.1)',
  dotColor: 'rgba(0, 0, 0, 0.05)',
  smartGuideColor: '#FF0066',  // Figma pink
  smartGuideWidth: 1,
};
```

---

## Performance Optimizations

### 1. Dirty Region Tracking
```typescript
class DirtyRegionManager {
  private regions: Rect[] = [];
  
  add(rect: Rect): void {
    // Merge overlapping regions
    this.regions = this.mergeRegions([...this.regions, rect]);
  }
  
  clear(): void {
    this.regions = [];
  }
  
  getRegions(): Rect[] {
    return this.regions;
  }
  
  private mergeRegions(regions: Rect[]): Rect[] {
    // Union-find or simple merging
    // Return minimal set of non-overlapping regions
  }
}
```

### 2. Layered Rendering
- **Layer 0**: Grid/Rulers (static, cached)
- **Layer 1**: Selection boxes (dynamic)
- **Layer 2**: Transform handles (interactive)
- **Layer 3**: Tool previews (ephemeral)

### 3. Request Animation Frame Batching
```typescript
class BatchedRenderer {
  private pendingRenders: Set<string> = new Set();
  
  schedule(elementId: string): void {
    this.pendingRenders.add(elementId);
    
    if (!this.rafScheduled) {
      this.rafScheduled = true;
      requestAnimationFrame(() => this.flush());
    }
  }
  
  private flush(): void {
    this.pendingRenders.forEach(id => this.renderElement(id));
    this.pendingRenders.clear();
    this.rafScheduled = false;
  }
}
```

---

## Event Handling

```typescript
// src/core/interactions/CanvasEvents.ts

class CanvasEventManager {
  private canvas: HTMLCanvasElement;
  private viewport: ViewportManager;
  private toolManager: ToolManager;
  
  // Event handlers
  private onMouseDown(e: MouseEvent): void;
  private onMouseMove(e: MouseEvent): void;
  private onMouseUp(e: MouseEvent): void;
  private onWheel(e: WheelEvent): void;
  private onKeyDown(e: KeyboardEvent): void;
  
  // Coordinate conversion
  private getCanvasPoint(e: MouseEvent): Point {
    const rect = this.canvas.getBoundingClientRect();
    return {
      x: e.clientX - rect.left,
      y: e.clientY - rect.top
    };
  }
  
  // Gesture handling
  private handlePan(delta: Point): void;
  private handleZoom(factor: number, center: Point): void;
  
  // Tool delegation
  private delegateToTool(tool: Tool, event: CanvasEvent): void;
}
```

---

## CSS Styling (Visual Polish)

```css
/* Canvas container */
.canvas-container {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: #E5E5E5;  /* Checkerboard pattern via CSS */
  background-image: 
    linear-gradient(45deg, #D4D4D4 25%, transparent 25%),
    linear-gradient(-45deg, #D4D4D4 25%, transparent 25%),
    linear-gradient(45deg, transparent 75%, #D4D4D4 75%),
    linear-gradient(-45deg, transparent 75%, #D4D4D4 75%);
  background-size: 20px 20px;
  background-position: 0 0, 0 10px, 10px -10px, -10px 0px;
}

/* Canvas overlay */
.canvas-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: auto;  /* Capture events */
  z-index: 10;
}

/* Iframe preview */
.preview-iframe {
  position: absolute;
  border: none;
  background: white;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}
```

---

## API Reference

```typescript
// Main Canvas API

interface CanvasEngine {
  // Initialization
  mount(container: HTMLElement): void;
  unmount(): void;
  
  // View control
  zoom(factor: number, animate?: boolean): void;
  pan(x: number, y: number): void;
  setZoomRange(min: number, max: number): void;
  
  // Content
  loadContent(html: string): Promise<void>;
  getContentDocument(): Document | null;
  
  // Selection
  select(elements: Element[]): void;
  deselect(elements?: Element[]): void;
  getSelection(): Element[];
  
  // Transform
  setTransform(element: Element, transform: Transform): void;
  getTransform(element: Element): Transform;
  
  // Tools
  setActiveTool(tool: ToolType): void;
  getActiveTool(): ToolType;
  
  // Events
  onSelectionChange(callback: (elements: Element[]) => void): Unsubscribe;
  onTransformChange(callback: (element: Element, transform: Transform) => void): Unsubscribe;
}
```

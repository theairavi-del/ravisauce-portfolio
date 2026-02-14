# Visual Website Builder - System Architecture

## Overview
A pure client-side visual website builder that allows users to import, edit, and export websites using a Figma-like interface.

## Core Philosophy
- **Hybrid Rendering**: DOM-based preview (iframe) + Canvas overlay (UI/interactions)
- **Pure Client-Side**: No server required for MVP
- **Web Standards**: Built on modern browser APIs
- **Performance First**: Lazy loading, virtualization, efficient rendering

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              APPLICATION LAYER                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Toolbar    │  │   Canvas     │  │   Layers     │  │  Properties  │     │
│  │   (Tools)    │  │   (Preview)  │  │   (Tree)     │  │   (Editor)   │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                  │                 │            │
│         └─────────────────┴──────────────────┴─────────────────┘            │
│                                  │                                          │
│                           ┌──────┴──────┐                                   │
│                           │  Store/State │                                   │
│                           │   Manager    │                                   │
│                           └──────┬──────┘                                   │
└──────────────────────────────────┼──────────────────────────────────────────┘
                                   │
┌──────────────────────────────────┼──────────────────────────────────────────┐
│                            CORE ENGINE LAYER                                 │
│                                │                                             │
│  ┌─────────────────────────────┼─────────────────────────────────────────┐   │
│  │                        RENDERING ENGINE                               │   │
│  │  ┌─────────────────┐  ┌────┴──────────┐  ┌─────────────────────┐     │   │
│  │  │   DOM Parser    │  │  Canvas       │  │  Transform Engine   │     │   │
│  │  │  (HTML/CSS/JS)  │  │  Overlay      │  │  (Move/Resize/Rot)  │     │   │
│  │  └─────────────────┘  └───────────────┘  └─────────────────────┘     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     LAYER/DOM SYNCHRONIZER                           │    │
│  │     (Keeps Layer Tree <-> DOM Tree in sync bidirectionally)         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      INTERACTION ENGINE                              │    │
│  │  (Selection, Dragging, Keyboard Shortcuts, Tool State Machine)       │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                   │
┌──────────────────────────────────┼──────────────────────────────────────────┐
│                         STORAGE & I/O LAYER                                  │
│                                │                                             │
│  ┌──────────────────┐  ┌───────┴────────┐  ┌──────────────────────────┐     │
│  │   File System    │  │    IndexedDB   │  │    Export/Generator      │     │
│  │   Access API     │  │   (Projects)   │  │   (HTML/CSS/Zip)         │     │
│  └──────────────────┘  └────────────────┘  └──────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

| Component | Technology | Reason |
|-----------|------------|--------|
| Framework | **Vanilla TypeScript** | Maximum performance, no framework overhead |
| State Management | **Custom Store** | Predictable, debuggable, time-travel |
| Rendering | **iframe + Canvas** | True preview + flexible overlay |
| Styling | **CSS Custom Properties** | Dynamic theming, runtime updates |
| File I/O | **File System Access API** | Native file operations |
| Storage | **IndexedDB** | Large binary data, structured storage |
| Bundling | **Vite** | Fast HMR, optimal builds |

---

## Module Breakdown

### 1. Core Types & Interfaces
```typescript
// src/types/index.ts

interface Project {
  id: string;
  name: string;
  createdAt: Date;
  modifiedAt: Date;
  rootLayer: Layer;
  assets: Asset[];
  viewport: ViewportState;
}

interface Layer {
  id: string;
  type: LayerType;
  name: string;
  domPath: string;          // CSS selector path to element
  element: HTMLElement;     // Reference to actual DOM element
  parent: Layer | null;
  children: Layer[];
  
  // Visual properties
  visible: boolean;
  locked: boolean;
  collapsed: boolean;
  
  // Transform
  transform: Transform;
  
  // Computed styles (cached)
  computedStyles: ComputedCSS;
}

enum LayerType {
  CONTAINER = 'container',  // div, section, etc
  TEXT = 'text',           // p, h1-h6, span
  IMAGE = 'image',         // img, picture
  COMPONENT = 'component', // Custom components
  ROOT = 'root'            // html/body
}

interface Transform {
  x: number;
  y: number;
  width: number;
  height: number;
  rotation: number;
  scaleX: number;
  scaleY: number;
}

interface Tool {
  id: ToolType;
  name: string;
  icon: string;
  cursor: string;
  shortcut: string;
}

enum ToolType {
  MOVE = 'move',        // V
  FRAME = 'frame',      // F
  RECTANGLE = 'rect',   // R
  CIRCLE = 'circle',    // O
  TEXT = 'text',        // T
  IMAGE = 'image',      // I
  HAND = 'hand'         // H
}

interface EditorState {
  tool: ToolType;
  zoom: number;
  pan: { x: number; y: number };
  selectedLayerIds: string[];
  hoveredLayerId: string | null;
  clipboard: Layer[];
  history: HistoryState;
}
```

---

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         UNIDIRECTIONAL DATA FLOW                         │
└─────────────────────────────────────────────────────────────────────────┘

   User Action
       │
       ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Action    │───▶│   Store     │───▶│   State     │───▶│   Render    │
│   (Intent)  │    │  (Reducer)  │    │   (Update)  │    │   (React)   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                               │
                                                               ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    User     │◀───│   Canvas    │◀───│    DOM      │◀───│   Engine    │
│   (Sees)    │    │  (Overlay)  │    │   (Update)  │    │   (Apply)   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                      BIDIRECTIONAL SYNC (Layers/DOM)                     │
└─────────────────────────────────────────────────────────────────────────┘

   DOM Change (external)
       │
       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   DOM       │────────▶│   Sync      │────────▶│   Layer     │
│   Mutation  │         │   Engine    │         │   Tree      │
│   Observer  │         │             │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
                                                        │
       ┌────────────────────────────────────────────────┘
       │
       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│    DOM      │◀────────│   Sync      │◀────────│   Property  │
│   (Updated) │         │   Engine    │         │   Change    │
│             │         │             │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
```

---

## Rendering Strategy

### Hybrid Rendering Explained

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CANVAS VIEWPORT                                │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                     CANVAS OVERLAY (UI Layer)                      │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │  Selection Box                                              │  │  │
│  │  │  ┌──────────────┐  Transform Handles                        │  │  │
│  │  │  │ ┌──┐    ┌──┐ │  (Corners/Edges)                          │  │  │
│  │  │  │ │  │    │  │ │                                           │  │  │
│  │  │  │ └──┘    └──┘ │  Guides (Smart/Grid)                      │  │  │
│  │  │  │              │                                           │  │  │
│  │  │  │ ┌──────────┐ │  Rulers                                   │  │  │
│  │  │  │ │  IFRAME  │ │                                           │  │  │
│  │  │  │ │          │ │  Marquee Selection                        │  │  │
│  │  │  │ │  ┌────┐  │ │                                           │  │  │
│  │  │  │ │  │    │  │ │  Tool Previews (drawing, etc)             │  │  │
│  │  │  │ │  │    │  │ │                                           │  │  │
│  │  │  │ │  └────┘  │ │  Hover Highlights                         │  │  │
│  │  │  │ │          │ │                                           │  │  │
│  │  │  │ └──────────┘ │                                           │  │  │
│  │  │  └──────────────┘                                           │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                                                                    │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                    PREVIEW IFRAME                            │  │  │
│  │  │  ┌─────────────────────────────────────────────────────┐    │  │  │
│  │  │  │                    USER'S WEBSITE                    │    │  │  │
│  │  │  │  ┌─────┐  ┌─────────────────┐  ┌─────┐             │    │  │  │
│  │  │  │  │ Nav │  │    Hero         │  │ Btn │             │    │  │  │
│  │  │  │  └─────┘  └─────────────────┘  └─────┘             │    │  │  │
│  │  │  │                                                    │    │  │  │
│  │  │  │  ┌─────────────────────────────────────────────┐   │    │  │  │
│  │  │  │  │              Content Section                 │   │    │  │  │
│  │  │  │  └─────────────────────────────────────────────┘   │    │  │  │
│  │  │  │                                                    │    │  │  │
│  │  │  │  ┌─────────────────────────────────────────────┐   │    │  │  │
│  │  │  │  │              Footer Section                  │   │    │  │  │
│  │  │  │  └─────────────────────────────────────────────┘   │    │  │  │
│  │  │  └─────────────────────────────────────────────────────┘    │  │  │
│  │  │                                                              │  │  │
│  │  │  (Actual DOM - true rendering, CSS applies correctly)        │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

**Why iframe?**
- True CSS rendering (no simulation needed)
- Isolated styles (user's CSS won't break editor)
- Real JavaScript execution
- Responsive breakpoints work correctly
- Media queries function properly

**Why Canvas overlay?**
- Smooth selection boxes without layout thrashing
- Transform handles independent of content
- Rulers, guides, smart snapping visuals
- Cross-browser consistent rendering
- Hardware accelerated for interactions

---

## Store Architecture (State Management)

```typescript
// src/store/index.ts

interface Store {
  // Project data
  project: Project;
  
  // Editor state
  editor: EditorState;
  
  // UI state
  ui: UIState;
  
  // Computed/cached
  computed: {
    selectedLayers: Layer[];
    layerMap: Map<string, Layer>;
    domToLayerMap: WeakMap<HTMLElement, Layer>;
  };
}

// Actions
const actions = {
  // Project
  project: {
    load: (files: FileSystemEntry[]) => void;
    save: () => Promise<void>;
    export: (format: 'html' | 'zip') => Promise<Blob>;
  },
  
  // Layers
  layers: {
    select: (ids: string[], mode: 'replace' | 'add' | 'toggle') => void;
    move: (id: string, parentId: string, index: number) => void;
    delete: (ids: string[]) => void;
    updateProperty: (id: string, property: string, value: any) => void;
    updateTransform: (id: string, transform: Partial<Transform>) => void;
    setVisibility: (id: string, visible: boolean) => void;
    setLocked: (id: string, locked: boolean) => void;
  },
  
  // Tools
  tools: {
    activate: (tool: ToolType) => void;
    deactivate: () => void;
  },
  
  // Canvas
  canvas: {
    zoom: (factor: number, center?: Point) => void;
    pan: (delta: Point) => void;
    resetView: () => void;
    fitToScreen: () => void;
  },
  
  // History
  history: {
    undo: () => void;
    redo: () => void;
    snapshot: () => void;
  }
};
```

---

## File Structure

```
/src
├── /core                    # Core engine modules
│   ├── /parser             # HTML/CSS/JS parsing
│   │   ├── HTMLParser.ts   # Parse HTML to internal format
│   │   ├── CSSParser.ts    # Parse and extract styles
│   │   └── AssetExtractor.ts # Extract images, fonts, etc
│   │
│   ├── /renderer           # Rendering engines
│   │   ├── CanvasOverlay.ts    # Canvas UI overlay
│   │   ├── IframeManager.ts    # Preview iframe management
│   │   ├── SelectionRenderer.ts # Selection boxes
│   │   └── TransformControls.ts # Resize/rotate handles
│   │
│   ├── /sync               # DOM <-> Layer synchronization
│   │   ├── DOMMutationObserver.ts
│   │   ├── LayerSyncEngine.ts
│   │   └── StyleSyncEngine.ts
│   │
│   └── /interactions       # Input handling
│       ├── ToolStateMachine.ts
│       ├── DragManager.ts
│       └── KeyboardManager.ts
│
├── /store                  # State management
│   ├── index.ts           # Store creation
│   ├── actions.ts         # Action creators
│   ├── reducers.ts        # State reducers
│   └── selectors.ts       # Memoized selectors
│
├── /components             # UI Components
│   ├── /ui                # Generic UI
│   ├── /toolbar           # Tool palette
│   ├── /layers            # Layer panel
│   ├── /properties        # Property editors
│   └── /canvas            # Canvas viewport
│
├── /tools                  # Tool implementations
│   ├── BaseTool.ts
│   ├── MoveTool.ts
│   ├── FrameTool.ts
│   ├── ShapeTools.ts
│   ├── TextTool.ts
│   └── ImageTool.ts
│
├── /io                     # File I/O
│   ├── FileSystemManager.ts
│   ├── ProjectSerializer.ts
│   ├── ExportEngine.ts
│   └── IndexedDBManager.ts
│
├── /types                  # TypeScript definitions
│   └── index.ts
│
├── /utils                  # Utilities
│   ├── geometry.ts        # Point, Rect, Matrix math
│   ├── css.ts             # CSS parsing/computation
│   ├── dom.ts             # DOM traversal/helpers
│   └── events.ts          # Event utilities
│
└── main.ts                 # Entry point
```

---

## Performance Considerations

| Challenge | Solution |
|-----------|----------|
| Large DOM trees | Virtual scrolling in layers panel, lazy iframe loading |
| Frequent updates | Debounced sync, requestAnimationFrame batching |
| Canvas redraws | Dirty region tracking, only redraw changed areas |
| Memory pressure | Object pooling, WeakMap for element references |
| File sizes | Streaming ZIP generation, chunked uploads |
| History stack | Structural sharing (immutable), max 50 states |

---

## Security Model

```
IFRAME SANDBOXING
├── allow-scripts      (required for user JS)
├── allow-same-origin  (required for same-origin access)
├── CSP Headers        (prevent external requests)
├── Script Proxy       (intercept dangerous operations)
└── Style Isolation    (user styles can't escape iframe)
```

---

## MVP Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Project setup, build system
- [ ] Core type definitions
- [ ] Store architecture
- [ ] Canvas + iframe rendering

### Phase 2: Import & Display (Week 3-4)
- [ ] File upload (drag-drop)
- [ ] HTML/CSS parsing
- [ ] Asset extraction
- [ ] Layer tree generation
- [ ] Basic zoom/pan

### Phase 3: Selection & Layers (Week 5-6)
- [ ] Click selection
- [ ] Multi-select
- [ ] Layer panel
- [ ] Show/hide, lock/unlock
- [ ] Layer reordering

### Phase 4: Editing (Week 7-8)
- [ ] Move tool
- [ ] Transform (resize)
- [ ] Property editor
- [ ] Text editing
- [ ] Basic shapes

### Phase 5: Export (Week 9)
- [ ] HTML/CSS generation
- [ ] Asset bundling
- [ ] ZIP export
- [ ] File System Access save

---

## Open Questions

1. **Component Library Integration?** React/Vue component editing?
2. **Animation Support?** CSS animations, GSAP integration?
3. **Collaboration?** CRDT-based real-time collaboration?
4. **Plugins?** Extensible architecture for third-party tools?

---

*Architecture designed for Ravi's Visual Website Builder*
*Date: 2026-02-13*

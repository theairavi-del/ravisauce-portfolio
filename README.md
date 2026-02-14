# Ravi - Visual Website Builder

**The "Photoshop for Websites"** - A professional visual website editor inspired by Figma and Framer.

## Features

### Core Editor
- 🎨 **Visual Canvas** - Pan, zoom, and edit with smooth interactions
- ✋ **Drag & Drop** - Move elements freely on the canvas
- 🔲 **Resize Handles** - 8-directional resizing like Photoshop
- 🎯 **Element Selection** - Single and multi-select with Shift
- ⌨️ **Keyboard Shortcuts** - V (select), T (text), R (rectangle), H (hand), etc.
- ↩️ **Undo/Redo** - Full history with Ctrl+Z / Ctrl+Shift+Z

### Properties Panel
- 📐 Position (X, Y) and Size (W, H)
- 🎨 Background color, text color, font size
- ⭕ Border radius and styling
- 📝 Direct text editing for text elements

### Components Library
- Hero sections
- Navigation bars
- Cards
- Buttons
- Forms
- Footers

### Import/Export
- 📥 Import HTML files
- 📤 Export clean HTML/CSS
- 💾 Save/load .ravi project files
- 📦 Import ZIP with HTML/CSS/JS

## Quick Start

### Option 1: Open Directly (No Backend)
Simply open `ravi.html` in your browser:
```bash
open ravi.html
```

### Option 2: With Backend (Full Features)

1. Install dependencies:
```bash
cd ravi-backend
npm install
```

2. Start the server:
```bash
npm start
```

3. Open in browser:
```
http://localhost:3000
```

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `V` | Select tool |
| `T` | Text tool |
| `R` | Rectangle tool |
| `I` | Image tool |
| `H` | Hand/Pan tool |
| `Delete` | Delete selected |
| `Ctrl+Z` | Undo |
| `Ctrl+Shift+Z` | Redo |
| `Ctrl+S` | Save project |
| `Ctrl+A` | Select all |
| `Ctrl+D` | Duplicate |
| `Space+Drag` | Pan canvas |
| `Scroll` | Zoom in/out |

## File Structure

```
ravi/
├── ravi.html              # Main application
├── ravi-app.css           # Application styles
├── ravi-engine.js         # Core editor engine
├── ravi-backend/          # Node.js server
│   ├── server.js          # Express server
│   ├── package.json       # Dependencies
│   └── README.md          # Backend docs
└── README.md              # This file
```

## API Endpoints

### Import/Export
- `POST /api/import/html` - Import HTML string
- `POST /api/import/zip` - Import ZIP file
- `POST /api/export/html` - Export to HTML

### Projects
- `POST /api/project/save` - Save project
- `GET /api/project/:id` - Load project
- `GET /api/projects` - List all projects

### Deploy
- `POST /api/deploy` - Deploy static site

## Development

The editor is built with vanilla JavaScript for maximum performance:
- No framework overhead
- 60fps interactions
- Optimized rendering

## License

MIT

---

Built with ❤️ by Vector for Ravisauce 2028
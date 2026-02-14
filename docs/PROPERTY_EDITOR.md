# Property Editor Technical Specification

## Overview
The Property Editor provides a comprehensive interface for editing element properties including text content, CSS styles, transforms, and visual effects. It features two-way binding with the selected layer.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      PROPERTY EDITOR ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         PROPERTY EDITOR PANEL                            │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  🔍 Search Properties...                                          │  │
│  ├───────────────────────────────────────────────────────────────────┤  │
│  │  ┌─ 📝 CONTENT ─────────────────────────────────────────────────┐ │  │
│  │  │  Text: [Welcome to our site!                    ]            │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌─ 🎨 APPEARANCE ──────────────────────────────────────────────┐ │  │
│  │  │                                                              │ │  │
│  │  │  Fill: [██████ #FF6B6B    ]  [+]                            │ │  │
│  │  │  Stroke: [██████ #4ECDC4  ]  [1px]  [solid]                 │ │  │
│  │  │  Opacity: [████████░░ 80%       ]                           │ │  │
│  │  │                                                              │ │  │
│  │  │  Shadow:  x:[ 0 ] y:[ 4 ] blur:[ 8 ] color:[██████ #00000020]│ │  │
│  │  │  Blur: [░░░░░░░░░░ 0px       ]                              │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌─ 📐 LAYOUT ──────────────────────────────────────────────────┐ │  │
│  │  │  Position: X:[ 100 ] Y:[ 200 ]                               │ │  │
│  │  │  Size:     W:[ 300 ] H:[ 150 ]                               │ │  │
│  │  │  Rotation: [    0°    ]                                       │ │  │
│  │  │                                                              │ │  │
│  │  │  Constraints: [ Left ▼ ] [ Top ▼ ]                            │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌─ 📏 SPACING ─────────────────────────────────────────────────┐ │  │
│  │  │         [  16  ]  ← Margin Top                               │ │  │
│  │  │  [ 24 ]       [ 24 ] ← Margin Left/Right                     │ │  │
│  │  │         [  16  ]  ← Margin Bottom                            │ │  │
│  │  │                                                              │ │  │
│  │  │         [  12  ]  ← Padding Top                              │ │  │
│  │  │  [ 20 ]       [ 20 ] ← Padding Left/Right                    │ │  │
│  │  │         [  12  ]  ← Padding Bottom                           │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌─ ✏️ TYPOGRAPHY ───────────────────────────────────────────────┐ │  │
│  │  │  Font: [ Inter                    ▼ ]                        │ │  │
│  │  │  Size: [ 16px ▼ ]  Weight: [ 400 ▼ ]                         │ │  │
│  │  │  Line: [ 1.5   ▼ ]  Letter: [ 0 ▼ ]                          │ │  │
│  │  │                                                              │ │  │
│  │  │  [ B ] [ I ] [ U ]    [🔲] [🟰] [🟧]                        │ │  │
│  │  │  Bold Italic Underline   Align                              │ │  │
│  │  │                                                              │ │  │
│  │  │  Color: [██████ #333333    ]                                │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌─ 🔲 BORDER ──────────────────────────────────────────────────┐ │  │
│  │  │  Radius: Top-Left:[ 4 ] Top-Right:[ 4 ]                      │ │  │
│  │  │         Bottom-Left:[ 4 ] Bottom-Right:[ 4 ]                 │ │  │
│  │  │  Width: [ 1px ▼ ]  Style: [ solid ▼ ]                        │ │  │
│  │  │  Color: [██████ #E0E0E0    ]                                │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                                                                   │  │
│  │  ┌─ ⚙️ ADVANCED ─────────────────────────────────────────────────┐ │  │
│  │  │  Display: [ block ▼ ]                                         │ │  │
│  │  │  Position: [ relative ▼ ]                                     │ │  │
│  │  │  Z-Index: [ auto ▼ ]                                          │ │  │
│  │  │  Overflow: [ visible ▼ ]                                      │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Core Components

```typescript
// src/components/properties/PropertyEditor.ts

interface PropertyEditorProps {
  layerManager: LayerManager;
  onPropertyChange: (property: string, value: any) => void;
}

class PropertyEditor {
  private element: HTMLElement;
  private layerManager: LayerManager;
  private sections: Map<string, PropertySection>;
  private currentLayer: Layer | null = null;
  
  mount(container: HTMLElement): void {
    this.element = document.createElement('div');
    this.element.className = 'property-editor';
    
    this.initializeSections();
    this.render();
    
    container.appendChild(this.element);
    
    // Subscribe to selection changes
    this.layerManager.subscribe(this.handleLayerEvent);
  }
  
  private initializeSections(): void {
    this.sections = new Map([
      ['content', new ContentSection()],
      ['appearance', new AppearanceSection()],
      ['layout', new LayoutSection()],
      ['spacing', new SpacingSection()],
      ['typography', new TypographySection()],
      ['border', new BorderSection()],
      ['effects', new EffectsSection()],
      ['advanced', new AdvancedSection()]
    ]);
  }
  
  private handleLayerEvent = (event: LayerEvent): void => {
    if (event.type === 'selected') {
      this.currentLayer = this.layerManager.getById(event.layerId);
      this.updateValues();
    }
  };
  
  private updateValues(): void {
    if (!this.currentLayer) {
      this.showEmptyState();
      return;
    }
    
    const layer = this.currentLayer;
    
    this.sections.forEach((section, key) => {
      section.setLayer(layer);
      section.updateValues();
    });
  }
  
  private showEmptyState(): void {
    this.element.innerHTML = `
      <div class="property-editor-empty">
        <p>Select a layer to edit its properties</p>
      </div>
    `;
  }
  
  private render(): void {
    this.element.innerHTML = `
      <div class="property-editor-header">
        <input type="text" class="property-search" placeholder="Search properties...">
      </div>
      <div class="property-sections">
        ${Array.from(this.sections.values()).map(s => s.render()).join('')}
      </div>
    `;
    
    this.attachEventListeners();
  }
  
  private attachEventListeners(): void {
    // Search functionality
    const searchInput = this.element.querySelector('.property-search');
    searchInput?.addEventListener('input', this.handleSearch);
  }
  
  private handleSearch = (e: Event): void => {
    const query = (e.target as HTMLInputElement).value.toLowerCase();
    
    this.sections.forEach(section => {
      const matches = section.matchesSearch(query);
      section.setVisible(matches);
    });
  };
}
```

---

## Property Sections

### 1. Content Section

```typescript
// src/components/properties/sections/ContentSection.ts

class ContentSection extends PropertySection {
  private textInput: HTMLTextAreaElement;
  private srcInput: HTMLInputElement;
  private altInput: HTMLInputElement;
  
  render(): string {
    const layer = this.getLayer();
    if (!layer) return '';
    
    if (layer.type === LayerType.TEXT) {
      return this.renderTextContent();
    } else if (layer.type === LayerType.IMAGE) {
      return this.renderImageContent();
    }
    
    return '';
  }
  
  private renderTextContent(): string {
    const text = this.layer?.content?.textContent || '';
    
    return `
      <div class="property-section" data-section="content">
        <div class="section-header">
          <span class="section-icon">📝</span>
          <span class="section-title">Content</span>
          <button class="section-toggle">▼</button>
        </div>
        <div class="section-content">
          <label>Text</label>
          <textarea class="property-input" data-property="textContent" rows="3">${this.escapeHtml(text)}</textarea>
        </div>
      </div>
    `;
  }
  
  private renderImageContent(): string {
    const src = this.layer?.content?.src || '';
    const alt = this.layer?.content?.alt || '';
    
    return `
      <div class="property-section" data-section="content">
        <div class="section-header">
          <span class="section-icon">🖼</span>
          <span class="section-title">Image</span>
          <button class="section-toggle">▼</button>
        </div>
        <div class="section-content">
          <label>Source</label>
          <input type="text" class="property-input" data-property="src" value="${src}">
          
          <label>Alt Text</label>
          <input type="text" class="property-input" data-property="alt" value="${alt}">
          
          <div class="image-preview">
            <img src="${src}" alt="Preview" onerror="this.style.display='none'">
          </div>
        </div>
      </div>
    `;
  }
  
  attachListeners(): void {
    this.element.querySelectorAll('.property-input').forEach(input => {
      input.addEventListener('input', this.handleInput);
      input.addEventListener('change', this.handleChange);
    });
  }
  
  private handleInput = (e: Event): void => {
    const input = e.target as HTMLInputElement;
    const property = input.dataset.property;
    const value = input.value;
    
    // Debounced update for text input
    this.debouncedUpdate(property!, value);
  };
  
  private handleChange = (e: Event): void => {
    const input = e.target as HTMLInputElement;
    const property = input.dataset.property;
    const value = input.value;
    
    // Immediate update on blur/enter
    this.updateProperty(property!, value);
  };
  
  private updateProperty(property: string, value: any): void {
    if (!this.layer) return;
    
    // Update layer content
    if (!this.layer.content) this.layer.content = {};
    this.layer.content[property] = value;
    
    // Update DOM
    if (property === 'textContent') {
      this.layer.element.textContent = value;
    } else if (property === 'src') {
      (this.layer.element as HTMLImageElement).src = value;
    } else if (property === 'alt') {
      (this.layer.element as HTMLImageElement).alt = value;
    }
    
    // Notify change
    this.emitChange(property, value);
  }
}
```

### 2. Layout Section

```typescript
// src/components/properties/sections/LayoutSection.ts

class LayoutSection extends PropertySection {
  render(): string {
    const layer = this.getLayer();
    if (!layer) return '';
    
    const bounds = layer.bounds;
    const transform = layer.transform;
    
    return `
      <div class="property-section" data-section="layout">
        <div class="section-header">
          <span class="section-icon">📐</span>
          <span class="section-title">Layout</span>
          <button class="section-toggle">▼</button>
        </div>
        <div class="section-content">
          <div class="property-row">
            <div class="property-group">
              <label>X</label>
              <input type="number" class="property-input" data-property="x" value="${Math.round(bounds.x)}">
            </div>
            <div class="property-group">
              <label>Y</label>
              <input type="number" class="property-input" data-property="y" value="${Math.round(bounds.y)}">
            </div>
          </div>
          
          <div class="property-row">
            <div class="property-group">
              <label>W</label>
              <input type="number" class="property-input" data-property="width" value="${Math.round(bounds.width)}">
            </div>
            <div class="property-group">
              <label>H</label>
              <input type="number" class="property-input" data-property="height" value="${Math.round(bounds.height)}">
            </div>
            <button class="lock-ratio" data-locked="true">🔒</button>
          </div>
          
          <div class="property-row">
            <div class="property-group">
              <label>Rotation</label>
              <div class="rotation-input">
                <input type="range" min="-180" max="180" value="${transform.rotation}" data-property="rotation">
                <input type="number" min="-180" max="180" value="${Math.round(transform.rotation)}" data-property="rotation">
                <span>°</span>
              </div>
            </div>
          </div>
          
          <div class="property-row">
            <div class="property-group">
              <label>Constraints</label>
              <div class="constraints">
                <select data-property="constraintHorizontal">
                  <option value="left">Left</option>
                  <option value="right">Right</option>
                  <option value="center">Center</option>
                  <option value="scale">Scale</option>
                </select>
                <select data-property="constraintVertical">
                  <option value="top">Top</option>
                  <option value="bottom">Bottom</option>
                  <option value="center">Center</option>
                  <option value="scale">Scale</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  private handleNumberInput = (e: Event): void => {
    const input = e.target as HTMLInputElement;
    const property = input.dataset.property;
    const value = parseFloat(input.value);
    
    this.updateTransform(property as keyof Transform, value);
  };
  
  private updateTransform(property: keyof Transform, value: number): void {
    if (!this.layer) return;
    
    // Update transform
    this.layer.transform[property] = value;
    
    // Update bounds if position/size changed
    if (property === 'x' || property === 'y' || property === 'width' || property === 'height') {
      this.layer.bounds[property] = value;
    }
    
    // Apply to element
    this.applyTransformToElement();
    
    this.emitChange(`transform.${property}`, value);
  }
  
  private applyTransformToElement(): void {
    if (!this.layer) return;
    
    const { x, y, width, height, rotation } = this.layer.transform;
    
    const element = this.layer.element;
    element.style.transform = `translate(${x}px, ${y}px) rotate(${rotation}deg)`;
    element.style.width = `${width}px`;
    element.style.height = `${height}px`;
  }
}
```

### 3. Appearance Section

```typescript
// src/components/properties/sections/AppearanceSection.ts

class AppearanceSection extends PropertySection {
  render(): string {
    const styles = this.layer?.computedStyles || {};
    
    return `
      <div class="property-section" data-section="appearance">
        <div class="section-header">
          <span class="section-icon">🎨</span>
          <span class="section-title">Appearance</span>
          <button class="section-toggle">▼</button>
        </div>
        <div class="section-content">
          <div class="property-row">
            <label>Fill</label>
            <div class="color-input-group">
              <input type="color" class="color-picker" data-property="backgroundColor" value="${this.rgbToHex(styles.backgroundColor) || '#ffffff'}">
              <input type="text" class="color-text" data-property="backgroundColor" value="${this.rgbToHex(styles.backgroundColor) || '#ffffff'}">
              <button class="add-fill">+</button>
            </div>
          </div>
          
          <div class="property-row">
            <label>Opacity</label>
            <div class="slider-input-group">
              <input type="range" min="0" max="100" value="${Math.round((parseFloat(styles.opacity) || 1) * 100)}" data-property="opacity">
              <input type="number" min="0" max="100" value="${Math.round((parseFloat(styles.opacity) || 1) * 100)}" data-property="opacity">
              <span>%</span>
            </div>
          </div>
          
          <div class="property-row">
            <label>Shadow</label>
            <div class="shadow-controls">
              <input type="number" placeholder="X" data-property="shadowX" value="0">
              <input type="number" placeholder="Y" data-property="shadowY" value="4">
              <input type="number" placeholder="Blur" data-property="shadowBlur" value="8">
              <input type="color" data-property="shadowColor" value="#00000040">
            </div>
          </div>
          
          <div class="property-row">
            <label>Blur</label>
            <div class="slider-input-group">
              <input type="range" min="0" max="50" value="0" data-property="blur">
              <input type="number" min="0" max="50" value="0" data-property="blur">
              <span>px</span>
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  private rgbToHex(rgb: string): string | null {
    // Convert rgb(r, g, b) to #RRGGBB
    const match = rgb?.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
    if (!match) return rgb;
    
    const r = parseInt(match[1]).toString(16).padStart(2, '0');
    const g = parseInt(match[2]).toString(16).padStart(2, '0');
    const b = parseInt(match[3]).toString(16).padStart(2, '0');
    
    return `#${r}${g}${b}`;
  }
  
  private handleColorChange = (e: Event): void => {
    const input = e.target as HTMLInputElement;
    const property = input.dataset.property;
    const value = input.value;
    
    // Sync color picker and text input
    const group = input.closest('.color-input-group');
    if (group) {
      const other = group.querySelector(input.type === 'color' ? '.color-text' : '.color-picker');
      if (other) (other as HTMLInputElement).value = value;
    }
    
    this.updateStyle(property!, value);
  };
  
  private updateStyle(property: string, value: string): void {
    if (!this.layer) return;
    
    // Map editor property names to CSS properties
    const propertyMap: Record<string, string> = {
      'backgroundColor': 'background-color',
      'opacity': 'opacity',
      'blur': 'filter'
    };
    
    const cssProperty = propertyMap[property] || property;
    
    // Handle special cases
    if (property === 'blur') {
      this.layer.element.style.filter = `blur(${value}px)`;
    } else if (property === 'opacity') {
      this.layer.element.style.opacity = (parseInt(value) / 100).toString();
    } else {
      this.layer.element.style[cssProperty as any] = value;
    }
    
    // Update computed styles cache
    this.layer.computedStyles[property] = value;
    
    this.emitChange(`style.${cssProperty}`, value);
  }
}
```

---

## Typography Section

```typescript
// src/components/properties/sections/TypographySection.ts

const FONT_OPTIONS = [
  'Inter', 'Roboto', 'Open Sans', 'Lato', 'Montserrat',
  'Poppins', 'Playfair Display', 'Merriweather', 'Source Sans Pro',
  'System UI', 'Arial', 'Georgia', 'Times New Roman'
];

const FONT_WEIGHTS = [
  { value: '100', label: 'Thin' },
  { value: '200', label: 'Extra Light' },
  { value: '300', label: 'Light' },
  { value: '400', label: 'Regular' },
  { value: '500', label: 'Medium' },
  { value: '600', label: 'Semi Bold' },
  { value: '700', label: 'Bold' },
  { value: '800', label: 'Extra Bold' },
  { value: '900', label: 'Black' }
];

class TypographySection extends PropertySection {
  render(): string {
    const styles = this.layer?.computedStyles || {};
    
    return `
      <div class="property-section" data-section="typography">
        <div class="section-header">
          <span class="section-icon">✏️</span>
          <span class="section-title">Typography</span>
          <button class="section-toggle">▼</button>
        </div>
        <div class="section-content">
          <div class="property-row">
            <label>Font Family</label>
            <select class="property-select" data-property="fontFamily">
              ${FONT_OPTIONS.map(font => `
                <option value="${font}" ${styles.fontFamily?.includes(font) ? 'selected' : ''}>${font}</option>
              `).join('')}
            </select>
          </div>
          
          <div class="property-row two-col">
            <div class="property-group">
              <label>Size</label>
              <input type="text" class="property-input" data-property="fontSize" value="${styles.fontSize || '16px'}">
            </div>
            <div class="property-group">
              <label>Weight</label>
              <select class="property-select" data-property="fontWeight">
                ${FONT_WEIGHTS.map(w => `
                  <option value="${w.value}" ${styles.fontWeight === w.value ? 'selected' : ''}>${w.label}</option>
                `).join('')}
              </select>
            </div>
          </div>
          
          <div class="property-row two-col">
            <div class="property-group">
              <label>Line Height</label>
              <input type="text" class="property-input" data-property="lineHeight" value="${styles.lineHeight || '1.5'}">
            </div>
            <div class="property-group">
              <label>Letter Spacing</label>
              <input type="text" class="property-input" data-property="letterSpacing" value="${styles.letterSpacing || '0'}">
            </div>
          </div>
          
          <div class="property-row">
            <div class="text-toolbar">
              <button class="toolbar-btn ${this.isBold(styles) ? 'active' : ''}" data-action="bold" title="Bold">B</button>
              <button class="toolbar-btn ${this.isItalic(styles) ? 'active' : ''}" data-action="italic" title="Italic">I</button>
              <button class="toolbar-btn ${this.isUnderline(styles) ? 'active' : ''}" data-action="underline" title="Underline">U</button>
              <div class="toolbar-divider"></div>
              <button class="toolbar-btn" data-action="align-left">⬅</button>
              <button class="toolbar-btn" data-action="align-center">⬍</button>
              <button class="toolbar-btn" data-action="align-right">➡</button>
            </div>
          </div>
          
          <div class="property-row">
            <label>Color</label>
            <div class="color-input-group">
              <input type="color" class="color-picker" data-property="color" value="${this.rgbToHex(styles.color) || '#000000'}">
              <input type="text" class="color-text" data-property="color" value="${this.rgbToHex(styles.color) || '#000000'}">
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  private isBold(styles: ComputedCSS): boolean {
    return styles.fontWeight === 'bold' || parseInt(styles.fontWeight) >= 700;
  }
  
  private isItalic(styles: ComputedCSS): boolean {
    return styles.fontStyle === 'italic';
  }
  
  private isUnderline(styles: ComputedCSS): boolean {
    return styles.textDecoration?.includes('underline');
  }
}
```

---

## CSS

```css
/* Property Editor Styles */
.property-editor {
  width: 240px;
  background: #2C2C2C;
  color: #E0E0E0;
  font-size: 11px;
  overflow-y: auto;
  border-left: 1px solid #404040;
}

.property-editor-empty {
  padding: 40px 20px;
  text-align: center;
  color: #888;
}

.property-editor-header {
  padding: 12px;
  border-bottom: 1px solid #404040;
}

.property-search {
  width: 100%;
  padding: 6px 10px;
  background: #1E1E1E;
  border: 1px solid #404040;
  border-radius: 4px;
  color: #E0E0E0;
  font-size: 11px;
}

.property-search:focus {
  outline: none;
  border-color: #0066FF;
}

/* Sections */
.property-section {
  border-bottom: 1px solid #404040;
}

.section-header {
  display: flex;
  align-items: center;
  padding: 10px 12px;
  cursor: pointer;
  user-select: none;
}

.section-header:hover {
  background: #333;
}

.section-icon {
  margin-right: 8px;
  font-size: 12px;
}

.section-title {
  flex: 1;
  font-weight: 500;
}

.section-toggle {
  background: transparent;
  border: none;
  color: #888;
  cursor: pointer;
  font-size: 10px;
}

.section-content {
  padding: 0 12px 12px;
}

/* Property Rows */
.property-row {
  margin-bottom: 10px;
}

.property-row.two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.property-group label,
.property-row > label {
  display: block;
  margin-bottom: 4px;
  color: #888;
  font-size: 10px;
  text-transform: uppercase;
}

.property-input,
.property-select {
  width: 100%;
  padding: 5px 8px;
  background: #1E1E1E;
  border: 1px solid #404040;
  border-radius: 3px;
  color: #E0E0E0;
  font-size: 11px;
}

.property-input:focus,
.property-select:focus {
  outline: none;
  border-color: #0066FF;
}

/* Color Input */
.color-input-group {
  display: flex;
  gap: 4px;
}

.color-input-group input[type="color"] {
  width: 28px;
  height: 24px;
  padding: 0;
  border: none;
  background: transparent;
  cursor: pointer;
}

.color-input-group .color-text {
  flex: 1;
}

/* Slider Input */
.slider-input-group {
  display: flex;
  align-items: center;
  gap: 6px;
}

.slider-input-group input[type="range"] {
  flex: 1;
}

.slider-input-group input[type="number"] {
  width: 45px;
}

/* Text Toolbar */
.text-toolbar {
  display: flex;
  gap: 2px;
  padding: 4px;
  background: #1E1E1E;
  border-radius: 4px;
}

.toolbar-btn {
  width: 28px;
  height: 24px;
  background: transparent;
  border: 1px solid transparent;
  border-radius: 3px;
  color: #888;
  cursor: pointer;
  font-weight: bold;
  font-size: 12px;
}

.toolbar-btn:hover {
  background: #333;
  color: #E0E0E0;
}

.toolbar-btn.active {
  background: #0066FF;
  color: white;
}

.toolbar-divider {
  width: 1px;
  background: #404040;
  margin: 2px 4px;
}
```

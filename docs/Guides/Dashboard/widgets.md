# Dashboard Widgets Guide

This guide explains how to configure and develop widgets for the SSH Dashboard Monitor.

## Built-in Widgets

### System Status Widget
```yaml
widgets:
  system_status:
    enabled: true
    position: [0, 0]
    size: [6, 4]
    refresh: 30
    
    metrics:
      - cpu_usage
      - memory_usage
      - disk_usage
      - network_io
```

### Service Status Widget
```yaml
widgets:
  service_status:
    enabled: true
    position: [6, 0]
    size: [6, 4]
    refresh: 60
    
    services:
      - ssh
      - monitoring
      - dashboard
```

### Active Sessions Widget
```yaml
widgets:
  active_sessions:
    enabled: true
    position: [0, 4]
    size: [12, 4]
    refresh: 30
    
    display:
      max_items: 10
      sort: "timestamp"
      order: "desc"
```

## Widget Development

### Widget Structure
```javascript
class CustomWidget extends Widget {
  static metadata = {
    name: "custom_widget",
    title: "Custom Widget",
    description: "A custom dashboard widget",
    version: "1.0.0"
  };
  
  constructor(config) {
    super(config);
    this.initialize();
  }
  
  async initialize() {
    // Initialize widget
  }
  
  async getData() {
    // Fetch widget data
    return data;
  }
  
  render() {
    // Render widget content
    return template;
  }
}
```

### Widget Registration
```javascript
// Register widget
dashboard.registerWidget(CustomWidget);

// Configure widget
dashboard.configureWidget("custom_widget", {
  enabled: true,
  position: [0, 0],
  size: [6, 4],
  refresh: 30
});
```

## Data Integration

### API Integration
```javascript
class APIWidget extends Widget {
  async getData() {
    const response = await fetch('/api/data');
    const data = await response.json();
    return this.transformData(data);
  }
  
  transformData(data) {
    // Transform API data
    return transformed;
  }
}
```

### WebSocket Integration
```javascript
class RealtimeWidget extends Widget {
  initialize() {
    this.socket = new WebSocket('ws://localhost:8080');
    this.socket.onmessage = this.handleMessage.bind(this);
  }
  
  handleMessage(event) {
    const data = JSON.parse(event.data);
    this.updateContent(data);
  }
}
```

## Widget Styling

### CSS Structure
```css
.widget {
  background: var(--widget-bg);
  border-radius: var(--widget-radius);
  padding: var(--widget-padding);
  
  .widget-header {
    font-size: var(--header-size);
    margin-bottom: var(--spacing);
  }
  
  .widget-content {
    height: calc(100% - var(--header-height));
    overflow-y: auto;
  }
}
```

### Theme Integration
```javascript
class ThemedWidget extends Widget {
  applyTheme() {
    const theme = dashboard.getTheme();
    this.element.style.setProperty('--widget-bg', theme.colors.surface);
    this.element.style.setProperty('--text-color', theme.colors.text);
  }
}
```

## Interactivity

### Event Handling
```javascript
class InteractiveWidget extends Widget {
  bindEvents() {
    this.element.querySelector('.refresh').addEventListener(
      'click',
      this.refresh.bind(this)
    );
    
    this.element.querySelector('.settings').addEventListener(
      'click',
      this.showSettings.bind(this)
    );
  }
  
  async refresh() {
    const data = await this.getData();
    this.updateContent(data);
  }
  
  showSettings() {
    dashboard.showWidgetSettings(this);
  }
}
```

### Drag and Drop
```javascript
class DraggableWidget extends Widget {
  enableDragDrop() {
    this.element.setAttribute('draggable', true);
    this.element.addEventListener('dragstart', this.handleDragStart.bind(this));
    this.element.addEventListener('dragend', this.handleDragEnd.bind(this));
  }
  
  handleDragStart(event) {
    event.dataTransfer.setData('widget/id', this.id);
    this.element.classList.add('dragging');
  }
  
  handleDragEnd() {
    this.element.classList.remove('dragging');
  }
}
```

## Widget Settings

### Configuration Panel
```javascript
class ConfigurableWidget extends Widget {
  getSettingsPanel() {
    return `
      <div class="widget-settings">
        <h3>Widget Settings</h3>
        <form>
          <div class="form-group">
            <label>Refresh Interval</label>
            <input type="number" name="refresh" value="${this.config.refresh}">
          </div>
          <div class="form-group">
            <label>Max Items</label>
            <input type="number" name="maxItems" value="${this.config.maxItems}">
          </div>
          <button type="submit">Save</button>
        </form>
      </div>
    `;
  }
  
  handleSettingsSave(form) {
    const formData = new FormData(form);
    this.updateConfig({
      refresh: parseInt(formData.get('refresh')),
      maxItems: parseInt(formData.get('maxItems'))
    });
  }
}
```

## Data Visualization

### Chart Integration
```javascript
class ChartWidget extends Widget {
  async renderChart() {
    const data = await this.getData();
    const ctx = this.element.querySelector('canvas').getContext('2d');
    
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'Values',
          data: data.values,
          borderColor: this.getThemeColor('primary')
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false
      }
    });
  }
}
```

### Table Integration
```javascript
class TableWidget extends Widget {
  renderTable(data) {
    return `
      <table class="widget-table">
        <thead>
          <tr>
            ${this.columns.map(col => `<th>${col.label}</th>`).join('')}
          </tr>
        </thead>
        <tbody>
          ${data.map(row => this.renderRow(row)).join('')}
        </tbody>
      </table>
    `;
  }
  
  renderRow(row) {
    return `
      <tr>
        ${this.columns.map(col => `<td>${row[col.key]}</td>`).join('')}
      </tr>
    `;
  }
}
```

## Best Practices

1. **Performance**
   - Efficient data fetching
   - Proper cleanup
   - Memory management
   - Caching

2. **User Experience**
   - Loading states
   - Error handling
   - Responsive design
   - Accessibility

3. **Development**
   - Code organization
   - Documentation
   - Testing
   - Maintainability

## Related Documentation

- [Dashboard Customization](customization.md)
- [UI Components](components.md)
- [API Integration](../Integration/api_integration.md)
- [Theme Development](theme_development.md)

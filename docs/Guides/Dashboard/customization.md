# Dashboard Customization Guide

This guide explains how to customize the SSH Dashboard Monitor interface.

## Theme Configuration

### Basic Theme
```yaml
theme:
  name: "default"  # default, dark, light
  custom: false
  
  colors:
    primary: "#007bff"
    secondary: "#6c757d"
    success: "#28a745"
    danger: "#dc3545"
    warning: "#ffc107"
    info: "#17a2b8"
```

### Custom Theme
```yaml
theme:
  name: "custom"
  custom: true
  
  colors:
    primary: "#1e88e5"
    secondary: "#757575"
    background: "#ffffff"
    surface: "#f5f5f5"
    text: "#212121"
    
  fonts:
    primary: "Roboto"
    secondary: "Open Sans"
    code: "Source Code Pro"
```

## Layout Configuration

### Dashboard Layout
```yaml
layout:
  sidebar:
    position: "left"  # left, right
    width: 250
    collapsible: true
  
  header:
    height: 60
    fixed: true
    
  content:
    padding: 20
    max_width: 1200
```

### Grid System
```yaml
grid:
  columns: 12
  breakpoints:
    xs: 0
    sm: 600
    md: 960
    lg: 1280
    xl: 1920
```

## Widget Configuration

### Widget Layout
```yaml
widgets:
  layout:
    - position: [0, 0]
      size: [6, 4]
      type: "system_status"
    - position: [6, 0]
      size: [6, 4]
      type: "active_sessions"
    - position: [0, 4]
      size: [12, 4]
      type: "metrics_graph"
```

### Widget Settings
```yaml
widget_settings:
  system_status:
    refresh: 30
    show_details: true
    metrics:
      - "cpu"
      - "memory"
      - "disk"
  
  active_sessions:
    refresh: 60
    max_items: 10
    show_details: true
  
  metrics_graph:
    type: "line"
    duration: "1h"
    metrics:
      - "cpu_usage"
      - "memory_usage"
```

## Custom Widgets

### Widget Definition
```javascript
class CustomWidget extends Widget {
  constructor(config) {
    super(config);
    this.name = "custom_widget";
    this.title = "Custom Widget";
  }
  
  async getData() {
    // Fetch widget data
    const data = await this.fetchData();
    return data;
  }
  
  render() {
    // Render widget content
    return `
      <div class="widget-content">
        ${this.renderData()}
      </div>
    `;
  }
}
```

### Widget Registration
```javascript
dashboard.registerWidget("custom_widget", CustomWidget);
```

## Navigation

### Menu Configuration
```yaml
navigation:
  menu:
    - title: "Dashboard"
      icon: "dashboard"
      path: "/"
    
    - title: "Monitoring"
      icon: "monitoring"
      children:
        - title: "System"
          path: "/monitoring/system"
        - title: "Services"
          path: "/monitoring/services"
```

### Quick Actions
```yaml
quick_actions:
  - title: "Restart Service"
    icon: "refresh"
    action: "service.restart"
    
  - title: "View Logs"
    icon: "list"
    action: "logs.view"
```

## Notifications

### Notification Settings
```yaml
notifications:
  position: "top-right"
  duration: 5000
  max_visible: 3
  
  types:
    success:
      icon: "check"
      color: "success"
    error:
      icon: "error"
      color: "danger"
```

### Custom Notifications
```javascript
dashboard.notify({
  type: "success",
  title: "Service Started",
  message: "SSH service has been started successfully",
  duration: 5000
});
```

## Charts and Graphs

### Chart Configuration
```yaml
charts:
  defaults:
    type: "line"
    responsive: true
    animation: true
    
  themes:
    light:
      background: "#ffffff"
      grid: "#f0f0f0"
      text: "#212121"
    dark:
      background: "#2d2d2d"
      grid: "#404040"
      text: "#ffffff"
```

### Custom Charts
```javascript
const chart = new Chart(ctx, {
  type: 'line',
  data: {
    labels: timeLabels,
    datasets: [{
      label: 'CPU Usage',
      data: cpuData,
      borderColor: theme.colors.primary
    }]
  },
  options: {
    responsive: true,
    animation: {
      duration: 1000
    }
  }
});
```

## Responsive Design

### Breakpoint Configuration
```yaml
responsive:
  breakpoints:
    mobile: 480
    tablet: 768
    desktop: 1024
    
  layouts:
    mobile:
      sidebar: "hidden"
      widgets: "stack"
    tablet:
      sidebar: "compact"
      widgets: "grid"
```

### Media Queries
```css
/* Mobile Layout */
@media (max-width: 480px) {
  .dashboard-container {
    padding: 10px;
  }
  
  .widget {
    width: 100%;
  }
}

/* Tablet Layout */
@media (min-width: 481px) and (max-width: 768px) {
  .dashboard-container {
    padding: 15px;
  }
  
  .widget {
    width: 50%;
  }
}
```

## Best Practices

1. **Design**
   - Consistent styling
   - Responsive layouts
   - Performance optimization
   - Accessibility

2. **Development**
   - Component reuse
   - Code organization
   - Error handling
   - Documentation

3. **User Experience**
   - Intuitive navigation
   - Clear feedback
   - Performance
   - Customization options

## Related Documentation

- [Widget Development](widget_development.md)
- [Theme Development](theme_development.md)
- [UI Components](ui_components.md)
- [Dashboard API](../Integration/api_integration.md)

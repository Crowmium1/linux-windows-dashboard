# Custom Plugins Guide

This guide explains how to create and manage custom plugins for SSH Dashboard Monitor.

## Plugin Architecture

### Plugin Types
- Monitoring plugins
- Authentication plugins
- Notification plugins
- Integration plugins
- UI plugins

### Plugin Structure
```
plugin/
├── __init__.py
├── plugin.yaml
├── main.py
├── config.py
└── tests/
    ├── __init__.py
    └── test_plugin.py
```

## Configuration

### Plugin Manifest
```yaml
# plugin.yaml
name: "custom-plugin"
version: "1.0.0"
author: "Your Name"
description: "Custom plugin for SSH Dashboard"
entry_point: "main:CustomPlugin"
dependencies:
  - "requests>=2.25.0"
  - "pyyaml>=5.4.0"
```

### Plugin Settings
```yaml
settings:
  enabled: true
  interval: 300
  config:
    api_key: "your-api-key"
    endpoint: "https://api.example.com"
```

## Development

### Base Plugin Class
```python
from ssh_dashboard.plugins import BasePlugin

class CustomPlugin(BasePlugin):
    def __init__(self, config):
        super().__init__(config)
        self.name = "custom-plugin"
        self.version = "1.0.0"
    
    def initialize(self):
        """Initialize plugin"""
        pass
    
    def cleanup(self):
        """Cleanup plugin"""
        pass
```

### Monitoring Plugin
```python
from ssh_dashboard.plugins import MonitoringPlugin

class CustomMonitor(MonitoringPlugin):
    def collect_metrics(self):
        """Collect custom metrics"""
        metrics = {
            'custom_metric': 42
        }
        return metrics
    
    def check_health(self):
        """Perform health check"""
        return True
```

### Authentication Plugin
```python
from ssh_dashboard.plugins import AuthPlugin

class CustomAuth(AuthPlugin):
    def authenticate(self, credentials):
        """Authenticate user"""
        username = credentials.get('username')
        password = credentials.get('password')
        
        # Implement authentication logic
        return True
    
    def get_user_info(self, username):
        """Get user information"""
        return {
            'username': username,
            'roles': ['user']
        }
```

### Notification Plugin
```python
from ssh_dashboard.plugins import NotificationPlugin

class CustomNotifier(NotificationPlugin):
    def send_notification(self, message, level='info'):
        """Send notification"""
        # Implement notification logic
        pass
    
    def format_message(self, message):
        """Format notification message"""
        return f"[{self.name}] {message}"
```

## Integration

### Plugin Registration
```python
def register_plugin():
    """Register plugin with SSH Dashboard"""
    return {
        'name': 'custom-plugin',
        'class': CustomPlugin,
        'config': {
            'enabled': True
        }
    }
```

### Event Handling
```python
def handle_event(event):
    """Handle dashboard events"""
    event_type = event.get('type')
    event_data = event.get('data')
    
    if event_type == 'custom.event':
        process_custom_event(event_data)
```

## Testing

### Unit Tests
```python
import unittest
from .main import CustomPlugin

class TestCustomPlugin(unittest.TestCase):
    def setUp(self):
        self.config = {
            'enabled': True
        }
        self.plugin = CustomPlugin(self.config)
    
    def test_initialization(self):
        self.plugin.initialize()
        self.assertTrue(self.plugin.is_initialized)
    
    def test_cleanup(self):
        self.plugin.cleanup()
        self.assertFalse(self.plugin.is_initialized)
```

### Integration Tests
```python
def test_plugin_integration():
    plugin = CustomPlugin(config)
    
    # Test plugin initialization
    plugin.initialize()
    assert plugin.is_initialized
    
    # Test plugin functionality
    result = plugin.process_event({'type': 'test'})
    assert result.success
    
    # Test plugin cleanup
    plugin.cleanup()
    assert not plugin.is_initialized
```

## Deployment

### Installation
```bash
# Install plugin
ssh-dashboard-ctl plugin install custom-plugin

# Enable plugin
ssh-dashboard-ctl plugin enable custom-plugin

# Disable plugin
ssh-dashboard-ctl plugin disable custom-plugin
```

### Configuration
```yaml
plugins:
  custom-plugin:
    enabled: true
    config:
      setting1: "value1"
      setting2: "value2"
```

## Examples

### Custom Monitor
```python
class SystemMonitor(MonitoringPlugin):
    def collect_metrics(self):
        metrics = {}
        
        # Collect CPU metrics
        cpu_usage = self.get_cpu_usage()
        metrics['cpu'] = cpu_usage
        
        # Collect memory metrics
        memory_usage = self.get_memory_usage()
        metrics['memory'] = memory_usage
        
        return metrics
    
    def get_cpu_usage(self):
        # Implement CPU usage collection
        pass
    
    def get_memory_usage(self):
        # Implement memory usage collection
        pass
```

### Custom Notifier
```python
class SlackNotifier(NotificationPlugin):
    def initialize(self):
        self.webhook_url = self.config.get('webhook_url')
        self.channel = self.config.get('channel')
    
    def send_notification(self, message, level='info'):
        payload = {
            'channel': self.channel,
            'text': self.format_message(message),
            'icon_emoji': ':lock:'
        }
        
        requests.post(self.webhook_url, json=payload)
```

## Best Practices

1. **Development**
   - Clear documentation
   - Proper error handling
   - Unit testing
   - Performance optimization

2. **Integration**
   - Minimal dependencies
   - Proper cleanup
   - Resource management
   - Version compatibility

3. **Maintenance**
   - Regular updates
   - Bug tracking
   - User feedback
   - Documentation

## Related Documentation

- [API Integration](api_integration.md)
- [Third Party Integration](third_party.md)
- [Plugin Development](plugin_development.md)
- [Core Services](../CoreServices/service_management.md)

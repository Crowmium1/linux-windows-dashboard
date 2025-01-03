# SSH Dashboard Configuration Guide

This guide explains how to configure the SSH Dashboard web interface.

## Configuration File

The main configuration file is located at `config/web/web.yaml`.

## Server Configuration

```yaml
server:
  port: 3000                # Web server port
  host: "localhost"         # Host to bind to
  cors:
    enabled: true          # Enable CORS
    origins:              # Allowed origins
      - "http://localhost:3000"
```

## Security Settings

```yaml
security:
  session:
    secret: "your-secret"   # Session secret key
    duration: 86400         # Session duration (seconds)
  csrf:
    enabled: true          # Enable CSRF protection
  rateLimit:
    enabled: true          # Enable rate limiting
    windowMs: 900000       # Time window (15 minutes)
    max: 100              # Max requests per window
```

## API Configuration

```yaml
api:
  version: "v1"            # API version
  prefix: "/api"           # API endpoint prefix
  timeout: 30000          # Request timeout (ms)
  rateLimit:
    enabled: true
    windowMs: 900000
    max: 1000
```

## UI Settings

```yaml
ui:
  theme: "light"           # UI theme (light/dark)
  refreshInterval: 30000   # Data refresh interval (ms)
  charts:
    resourceHistory: 3600  # Chart history (seconds)
    maxDataPoints: 120     # Max data points per chart
```

## Logging Configuration

```yaml
logging:
  level: "info"           # Log level
  format: "combined"      # Log format
  directory: "${HA_LOG_DIR}/web"
  maxSize: 10485760      # Max log file size (10MB)
  maxFiles: 5            # Number of log files to keep
```

## Service Integration

```yaml
services:
  ha:
    checkInterval: 30000   # HA check interval (ms)
  monitoring:
    dataRetention: 604800  # Data retention (7 days)
  security:
    sessionTimeout: 3600   # Session timeout (1 hour)
```

## Environment Variables

Add these to your `.envrc`:

```bash
# Web Server
export WEB_PORT=3000
export WEB_HOST="localhost"
export WEB_LOG_DIR="${HA_LOG_DIR}/web"

# Security
export WEB_SESSION_SECRET="your-secret-key"
export WEB_CSRF_SECRET="your-csrf-secret"

# API
export API_TIMEOUT=30000
export API_RATE_LIMIT=1000
```

## Chart Configuration

### Resource Usage Chart

```yaml
charts:
  resources:
    enabled: true
    interval: 30000       # Update interval (ms)
    history: 3600        # History to keep (seconds)
    thresholds:
      cpu: 80           # CPU warning threshold (%)
      memory: 80        # Memory warning threshold (%)
      disk: 90          # Disk warning threshold (%)
```

### Network Traffic Chart

```yaml
charts:
  network:
    enabled: true
    interval: 30000
    history: 3600
    interfaces:          # Interfaces to monitor
      - eth0
      - eth1
```

## Notification Settings

```yaml
notifications:
  enabled: true
  maxDisplay: 100        # Max notifications to show
  refreshInterval: 60000  # Refresh interval (ms)
  types:                 # Notification types to show
    - system
    - security
    - monitoring
```

## Best Practices

1. **Security**
   - Change default secrets
   - Enable CSRF protection
   - Configure appropriate rate limits
   - Use HTTPS in production

2. **Performance**
   - Adjust refresh intervals based on load
   - Set appropriate data retention periods
   - Configure log rotation

3. **Monitoring**
   - Set meaningful alert thresholds
   - Configure essential metrics
   - Enable relevant notifications

## Related Documentation

- [Overview](overview.md)
- [Installation Guide](installation.md)
- [User Guide](user_guide.md)
- [API Reference](api_reference.md)

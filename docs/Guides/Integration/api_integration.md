# API Integration Guide

This guide explains how to integrate with the SSH Dashboard Monitor API.

## API Overview

### Base URL
```
https://dashboard.example.com/api/v1
```

### Authentication
```http
Authorization: Bearer <api-token>
```

### Response Format
```json
{
  "status": "success",
  "data": {},
  "message": "Operation successful"
}
```

## Authentication

### API Keys
```bash
# Generate API key
ssh-dashboard-ctl api create-key \
  --name "integration-key" \
  --role "reader"

# List API keys
ssh-dashboard-ctl api list-keys

# Revoke API key
ssh-dashboard-ctl api revoke-key <key-id>
```

### Token Management
```javascript
// Request token
const response = await fetch('/api/auth/token', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    key: 'your-api-key'
  })
});

const { token } = await response.json();
```

## Endpoints

### System Status

#### Get Status
```http
GET /api/status
```

**Response**
```json
{
  "status": "success",
  "data": {
    "services": {
      "ssh": "running",
      "monitor": "running"
    },
    "resources": {
      "cpu": 25,
      "memory": 60
    }
  }
}
```

### Service Management

#### List Services
```http
GET /api/services
```

#### Service Control
```http
POST /api/services/{service}/{action}
```

Actions:
- start
- stop
- restart

### Monitoring

#### Get Metrics
```http
GET /api/metrics
```

Query Parameters:
- `type`: Metric type
- `from`: Start timestamp
- `to`: End timestamp

#### Get Events
```http
GET /api/events
```

## Client Libraries

### Python Client
```python
from ssh_dashboard import Client

client = Client('https://dashboard.example.com', 'api-token')

# Get status
status = client.get_status()

# Control service
client.service_control('ssh', 'restart')

# Get metrics
metrics = client.get_metrics(
    type='cpu',
    from_time='2025-01-01T00:00:00Z',
    to_time='2025-01-02T00:00:00Z'
)
```

### JavaScript Client
```javascript
import { SSHDashboard } from 'ssh-dashboard-client';

const client = new SSHDashboard({
  url: 'https://dashboard.example.com',
  token: 'api-token'
});

// Get status
const status = await client.getStatus();

// Control service
await client.serviceControl('ssh', 'restart');

// Get metrics
const metrics = await client.getMetrics({
  type: 'cpu',
  fromTime: '2025-01-01T00:00:00Z',
  toTime: '2025-01-02T00:00:00Z'
});
```

## Webhooks

### Configuration
```yaml
webhooks:
  enabled: true
  endpoints:
    - url: "https://api.example.com/webhook"
      events: ["system.*", "security.*"]
      secret: "webhook-secret"
```

### Event Format
```json
{
  "id": "evt_123",
  "type": "system.status",
  "created": "2025-01-03T08:42:33Z",
  "data": {
    "service": "ssh",
    "status": "running"
  }
}
```

## Error Handling

### Error Format
```json
{
  "status": "error",
  "error": {
    "code": "SERVICE_NOT_FOUND",
    "message": "Service 'xyz' not found"
  }
}
```

### Error Codes
- `UNAUTHORIZED`: Authentication failed
- `FORBIDDEN`: Permission denied
- `NOT_FOUND`: Resource not found
- `VALIDATION_ERROR`: Invalid input
- `INTERNAL_ERROR`: Server error

## Rate Limiting

### Headers
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1672736553
```

### Configuration
```yaml
rate_limit:
  enabled: true
  window: 900  # 15 minutes
  max_requests: 1000
```

## Pagination

### Request
```http
GET /api/events?page=2&per_page=100
```

### Response Headers
```http
X-Total-Count: 1420
X-Page: 2
X-Per-Page: 100
X-Total-Pages: 15
```

## Examples

### Service Integration
```python
def monitor_services():
    client = SSHDashboard(API_URL, API_TOKEN)
    
    # Get service status
    status = client.get_status()
    
    # Check thresholds
    if status['resources']['cpu'] > 80:
        alert_high_cpu()
    
    # Restart if needed
    if status['services']['ssh'] == 'failed':
        client.service_control('ssh', 'restart')
```

### Metric Collection
```python
def collect_metrics():
    client = SSHDashboard(API_URL, API_TOKEN)
    
    # Get metrics
    metrics = client.get_metrics(
        type='system',
        interval='5m',
        duration='1h'
    )
    
    # Store metrics
    store_metrics(metrics)
```

## Best Practices

1. **Authentication**
   - Secure token storage
   - Regular key rotation
   - Proper permissions
   - Error handling

2. **Performance**
   - Connection pooling
   - Request batching
   - Response caching
   - Rate limiting

3. **Error Handling**
   - Retry logic
   - Circuit breaking
   - Logging
   - Monitoring

## Related Documentation

- [Webhooks Guide](webhooks.md)
- [Third Party Integration](third_party.md)
- [Custom Plugins](custom_plugins.md)
- [Security Guide](../Security/security_configuration.md)

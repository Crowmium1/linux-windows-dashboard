# Webhooks Guide

This guide explains how to use webhooks with the SSH Dashboard Monitor.

## Overview

Webhooks allow external services to receive real-time notifications about events in your SSH Dashboard Monitor.

## Event Types

### System Events
- Service status changes
- Resource thresholds
- Configuration changes
- Backup completion

### Security Events
- Authentication attempts
- Key changes
- Access violations
- Security alerts

### Monitoring Events
- Health check results
- Performance alerts
- Service metrics
- Log events

## Configuration

### Basic Setup
```yaml
webhooks:
  enabled: true
  endpoint: "https://api.example.com/webhook"
  secret: "your-secret-key"
  events:
    - "system.*"
    - "security.auth.*"
    - "monitoring.alert.*"
```

### Multiple Endpoints
```yaml
endpoints:
  slack:
    url: "https://hooks.slack.com/services/xxx/yyy/zzz"
    events: ["alert.*"]
    format: "slack"
  
  custom:
    url: "https://api.example.com/webhook"
    events: ["*"]
    format: "json"
```

## Event Format

### JSON Format
```json
{
  "id": "evt_123456",
  "type": "security.auth.failed",
  "created": "2025-01-03T08:42:33Z",
  "data": {
    "user": "admin",
    "ip": "192.168.1.100",
    "reason": "Invalid key"
  }
}
```

### Slack Format
```json
{
  "text": "Security Alert: Failed authentication attempt",
  "attachments": [{
    "color": "danger",
    "fields": [
      {"title": "User", "value": "admin"},
      {"title": "IP", "value": "192.168.1.100"},
      {"title": "Reason", "value": "Invalid key"}
    ]
  }]
}
```

## Implementation

### Sending Webhooks
```javascript
async function sendWebhook(endpoint, data) {
  const signature = createSignature(data, endpoint.secret);
  
  await fetch(endpoint.url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Signature': signature
    },
    body: JSON.stringify(data)
  });
}
```

### Receiving Webhooks
```python
from flask import Flask, request
import hmac

app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def webhook():
    signature = request.headers.get('X-Signature')
    if not verify_signature(request.data, signature):
        return 'Invalid signature', 401
        
    event = request.json
    process_event(event)
    return 'OK', 200
```

## Security

### Authentication
- HMAC signatures
- API keys
- IP whitelisting
- TLS encryption

### Best Practices
1. Use HTTPS endpoints
2. Validate signatures
3. Implement retry logic
4. Monitor delivery status

## Testing

### Local Testing
```bash
# Test webhook delivery
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-Signature: ${signature}" \
  -d '{"type":"test","data":{}}' \
  https://api.example.com/webhook
```

### Event Simulation
```bash
# Simulate system event
ssh-dashboard-ctl simulate-event \
  --type system.status \
  --data '{"service":"ssh","status":"down"}'
```

## Monitoring

### Delivery Status
```bash
# View webhook logs
tail -f /var/log/ssh-dashboard/webhooks.log

# Check delivery status
ssh-dashboard-ctl webhooks status
```

### Metrics
- Delivery rate
- Response time
- Error rate
- Retry count

## Integration Examples

### Slack Integration
```yaml
webhooks:
  slack:
    url: "https://hooks.slack.com/services/xxx/yyy/zzz"
    channel: "#alerts"
    username: "SSH Monitor"
    icon_emoji: ":lock:"
```

### Custom Integration
```yaml
webhooks:
  custom:
    url: "https://api.example.com/events"
    headers:
      Authorization: "Bearer ${API_KEY}"
    retry:
      max_attempts: 3
      delay: 60
```

## Troubleshooting

### Common Issues

1. **Delivery Failures**
   - Network connectivity
   - Invalid endpoints
   - Authentication errors
   - Rate limiting

2. **Integration Issues**
   - Format mismatch
   - Missing fields
   - Invalid signatures
   - Timeout issues

### Debug Mode
```yaml
webhooks:
  debug: true
  log_level: "debug"
  log_file: "/var/log/ssh-dashboard/webhooks.log"
```

## Best Practices

1. **Implementation**
   - Use HTTPS
   - Implement authentication
   - Add retry logic
   - Monitor deliveries

2. **Performance**
   - Batch events
   - Implement queuing
   - Set timeouts
   - Handle failures

3. **Security**
   - Validate payloads
   - Use strong secrets
   - Implement rate limiting
   - Monitor usage

## Related Documentation

- [API Integration](api_integration.md)
- [Third Party Integration](third_party.md)
- [Custom Plugins](custom_plugins.md)
- [Monitoring](../Monitoring/monitoring.md)

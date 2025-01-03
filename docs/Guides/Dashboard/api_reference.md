# SSH Dashboard API Reference

This document provides detailed information about the SSH Dashboard API endpoints.

## API Overview

Base URL: `http://localhost:3000/api`
Version: v1
Format: JSON

## Authentication

All API requests require authentication. Use session-based authentication or API keys.

## Endpoints

### System Status

#### Get System Status
```http
GET /status
```

**Response**
```json
{
    "services": "running",
    "ha": "active",
    "security": "healthy",
    "monitoring": "active",
    "resources": {
        "cpu": 25,
        "memory": 60,
        "disk": 45
    }
}
```

### Service Management

#### Get Service Status
```http
GET /services/{service}/status
```

**Parameters**
- `service`: Service name

**Response**
```json
{
    "status": "running",
    "uptime": "2d 3h 45m",
    "pid": 1234,
    "memory": "256MB"
}
```

#### Start Service
```http
POST /services/{service}/start
```

**Parameters**
- `service`: Service name

#### Stop Service
```http
POST /services/{service}/stop
```

#### Restart Service
```http
POST /services/{service}/restart
```

### Monitoring

#### Get Resource Usage
```http
GET /monitoring/resources
```

**Response**
```json
{
    "timestamps": ["2025-01-03T08:00:00Z", ...],
    "cpu": [25, 30, 28],
    "memory": [60, 62, 58],
    "disk": [45, 45, 46]
}
```

#### Get Service Metrics
```http
GET /monitoring/services/{service}/metrics
```

### Security

#### Get Security Status
```http
GET /security/status
```

**Response**
```json
{
    "ssh_keys": {
        "valid": 3,
        "expired": 0,
        "issues": []
    },
    "auth_logs": {
        "failed_attempts": 0,
        "last_login": "2025-01-03T08:00:00Z"
    }
}
```

#### Get SSH Keys
```http
GET /security/ssh-keys
```

#### Add SSH Key
```http
POST /security/ssh-keys
```

**Request Body**
```json
{
    "name": "user-key",
    "key": "ssh-rsa AAAA..."
}
```

#### Remove SSH Key
```http
DELETE /security/ssh-keys/{keyId}
```

### Logs

#### Get Logs
```http
GET /logs
```

**Query Parameters**
- `service`: Service name (optional)
- `lines`: Number of lines (default: 100)
- `level`: Log level (optional)

**Response**
```json
{
    "logs": [
        "2025-01-03T08:00:00Z [INFO] Service started",
        "2025-01-03T08:01:00Z [INFO] Health check passed"
    ]
}
```

### Events

#### Get Events
```http
GET /events
```

**Query Parameters**
- `type`: Event type (optional)
- `from`: Start timestamp
- `to`: End timestamp
- `limit`: Max events (default: 100)

### High Availability

#### Get HA Status
```http
GET /ha/status
```

**Response**
```json
{
    "mode": "primary",
    "peer_status": "connected",
    "last_sync": "2025-01-03T08:00:00Z"
}
```

#### Switch HA Node
```http
POST /ha/switch
```

**Request Body**
```json
{
    "node": "secondary"
}
```

## Error Handling

### Error Response Format
```json
{
    "error": {
        "code": "ERROR_CODE",
        "message": "Error description"
    }
}
```

### Common Error Codes
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `500`: Internal Server Error

## Rate Limiting

- Default: 1000 requests per 15 minutes
- Headers:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

## Best Practices

1. **Authentication**
   - Use HTTPS in production
   - Rotate API keys regularly
   - Use appropriate scopes

2. **Performance**
   - Implement caching
   - Use pagination
   - Minimize request frequency

3. **Error Handling**
   - Handle errors gracefully
   - Implement retries
   - Log API errors

## Related Documentation

- [Overview](overview.md)
- [Installation Guide](installation.md)
- [Configuration Guide](configuration.md)
- [User Guide](user_guide.md)

# SSH Dashboard Overview

The SSH Dashboard provides a modern web interface for managing and monitoring your SSH infrastructure.

## Features

- Real-time system monitoring
- Service management
- Resource usage visualization
- Security monitoring
- Log viewing and analysis
- High availability management

## Architecture

```
lib/web/
├── api/           # Backend API server
├── static/        # Static assets (JS, CSS)
└── templates/     # HTML templates

config/web/
└── web.yaml       # Web interface configuration
```

## Components

1. **Frontend**
   - Modern, responsive UI
   - Real-time updates
   - Interactive charts
   - Notification system

2. **Backend**
   - RESTful API
   - Service integration
   - Security middleware
   - Event handling

3. **Configuration**
   - Server settings
   - Security options
   - UI preferences
   - Service integration

## Getting Started

1. Install dependencies:
   ```bash
   npm install
   ```

2. Configure settings in `config/web/web.yaml`

3. Start the server:
   ```bash
   node lib/web/api/server.js
   ```

4. Access dashboard at `http://localhost:3000`

## Related Documentation

- [Installation Guide](installation.md)
- [Configuration Guide](configuration.md)
- [User Guide](user_guide.md)
- [API Reference](api_reference.md)
- [Development Guide](development.md)

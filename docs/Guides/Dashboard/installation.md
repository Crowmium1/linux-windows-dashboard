# SSH Dashboard Installation Guide

This guide explains how to install and set up the SSH Dashboard web interface.

## Prerequisites

- Node.js 14.x or higher
- npm 6.x or higher
- SSH Dashboard Monitor core components installed

## Installation Steps

1. **Install Dependencies**

   ```bash
   cd /opt/ssh_dashboard
   npm install express cors js-yaml chart.js
   ```

2. **Configure Web Server**

   Edit `config/web/web.yaml`:
   ```yaml
   server:
     port: 3000
     host: "localhost"
   ```

3. **Set Up Environment**

   Add to `.envrc`:
   ```bash
   export WEB_PORT=3000
   export WEB_HOST="localhost"
   export WEB_LOG_DIR="${HA_LOG_DIR}/web"
   ```

4. **Create Log Directory**

   ```bash
   mkdir -p "${WEB_LOG_DIR}"
   chmod 755 "${WEB_LOG_DIR}"
   ```

5. **Configure Systemd Service**

   Create `/etc/systemd/system/ssh-dashboard-web.service`:
   ```ini
   [Unit]
   Description=SSH Dashboard Web Interface
   After=network.target

   [Service]
   Type=simple
   ExecStart=/usr/bin/node /opt/ssh_dashboard/lib/web/api/server.js
   WorkingDirectory=/opt/ssh_dashboard
   Restart=always
   User=ssh-dashboard

   [Install]
   WantedBy=multi-user.target
   ```

6. **Start Service**

   ```bash
   systemctl daemon-reload
   systemctl enable ssh-dashboard-web
   systemctl start ssh-dashboard-web
   ```

## Security Configuration

1. **Configure CORS**

   Update `web.yaml`:
   ```yaml
   security:
     cors:
       enabled: true
       origins: ["http://localhost:3000"]
   ```

2. **Set Up Session Security**

   ```yaml
   security:
     session:
       secret: "<your-secret-key>"
       duration: 86400
   ```

3. **Configure Rate Limiting**

   ```yaml
   security:
     rateLimit:
       enabled: true
       windowMs: 900000
       max: 100
   ```

## Verification

1. **Check Service Status**

   ```bash
   systemctl status ssh-dashboard-web
   ```

2. **Verify Web Access**

   Open `http://localhost:3000` in a browser

3. **Check Logs**

   ```bash
   tail -f "${WEB_LOG_DIR}/access.log"
   ```

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   - Check Node.js installation
   - Verify file permissions
   - Check port availability

2. **Web Interface Not Accessible**
   - Verify service is running
   - Check firewall settings
   - Confirm port configuration

3. **API Errors**
   - Check service manager status
   - Verify file permissions
   - Review API logs

## Next Steps

1. [Configure the dashboard](configuration.md)
2. [Set up users and permissions](user_guide.md)
3. [Customize the interface](development.md)

## Related Documentation

- [Overview](overview.md)
- [Configuration Guide](configuration.md)
- [User Guide](user_guide.md)
- [API Reference](api_reference.md)

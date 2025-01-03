# Service Management Guide

This guide explains how to manage services in the SSH Dashboard Monitor project.

## Overview

The service management system consists of:
- Service Manager (`service_manager.sh`)
- Service Configuration (`service.yaml`)
- Systemd Service Files
- Installation Script

## Service Manager

### Basic Commands

```bash
# Start a service
./service_manager.sh start ssh-ha

# Stop a service
./service_manager.sh stop ssh-ha

# Restart a service
./service_manager.sh restart ssh-ha

# Check service status
./service_manager.sh status

# Check specific service health
./service_manager.sh check ssh-ha
```

### Service States

- **running**: Service is running normally
- **stopped**: Service is not running
- **degraded**: Service is running but with issues
- **unknown**: Service state cannot be determined

## Configuration

### Service Configuration (service.yaml)

```yaml
services:
  ssh-ha:
    name: "SSH High Availability Service"
    type: "systemd"
    restart: "always"
    
  ssh-monitor:
    name: "SSH Monitoring Service"
    type: "systemd"
    restart: "on-failure"
```

### Environment Variables

Global variables (`.config/direnv/global.envrc`):
- `SSH_PORT`: Default SSH port
- `MONITOR_PORT`: Monitor service port
- `HA_LOG_DIR`: Log directory path
- `HA_STATE_DIR`: State directory path

Project variables (`.envrc`):
- Service-specific overrides
- Local path configurations

## Installation

Run the installation script as root:
```bash
sudo ./scripts/install_services.sh
```

The script will:
1. Copy files to `/opt/ssh_dashboard`
2. Install systemd service files
3. Set correct permissions
4. Enable services
5. Verify installation

## Health Checks

The service manager performs:
- Port availability checks
- Process status checks
- Resource usage monitoring
- Log monitoring

## Logging

Logs are stored in:
- Main log: `${HA_LOG_DIR}/service/service.log`
- Service-specific: `${HA_LOG_DIR}/service/<service_name>.log`

Log rotation settings:
- Max size: 10MB
- Keep last 5 files

## Troubleshooting

### Common Issues

1. **Service Won't Start**
   - Check service dependencies
   - Verify SSH key permissions
   - Check log files

2. **Service Shows Degraded**
   - Check port availability
   - Monitor resource usage
   - Review service logs

3. **Lock File Issues**
   - Check for stale locks
   - Verify process status
   - Clear lock if necessary

### Service Recovery

1. **Manual Recovery**
   ```bash
   # Stop service
   ./service_manager.sh stop <service>
   
   # Clear state
   rm -f "${HA_STATE_DIR}/<service>_status"
   
   # Restart service
   ./service_manager.sh start <service>
   ```

2. **Automatic Recovery**
   - Services auto-restart based on configuration
   - HA service: Always restarts
   - Monitor service: Restarts on failure

## Related Documentation

- [Utilities Guide](utilities.md)
- [High Availability Guide](high_availability.md)
- [Monitoring Guide](monitoring_configuration.md)

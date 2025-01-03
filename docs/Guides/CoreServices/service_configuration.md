# Service Configuration Guide

This guide explains how to configure services in the SSH Dashboard Monitor project.

## Configuration File

The service configuration is stored in `config/service/service.yaml`.

## Structure

### Dependencies

```yaml
dependencies:
  commands:
    - ssh
    - rsync
  services:
    - sshd
    - network.service
```

Required commands and services are checked during service startup.

### Service Definitions

```yaml
services:
  ssh-ha:
    name: "SSH High Availability Service"
    type: "systemd"
    exec_start: "/usr/local/bin/ssh-ha start"
    restart: "always"
    
  ssh-monitor:
    name: "SSH Monitoring Service"
    type: "systemd"
    exec_start: "/usr/local/bin/ssh-monitor start"
    restart: "on-failure"
```

### Health Checks

```yaml
health_check:
  interval: 30  # seconds
  timeout: 5    # seconds
  retries: 3
  checks:
    - type: "port"
      port: 22
    - type: "process"
      name: "sshd"
```

### Resource Limits

```yaml
limits:
  cpu: 50       # percentage
  memory: 256   # MB
  nofile: 1024  # max open files
  nproc: 64     # max processes
```

### Logging

```yaml
logging:
  directory: "/var/log/ssh-dashboard"
  max_size: 10485760  # 10MB
  max_files: 5
  level: "info"
```

### Notifications

```yaml
notifications:
  startup: true
  shutdown: true
  failure: true
  channels:
    - type: "email"
      recipients: ["admin@example.com"]
    - type: "slack"
      webhook: ""
```

## Environment Integration

### Global Settings

In `.config/direnv/global.envrc`:
```bash
export SSH_PORT=22
export MONITOR_PORT=5000
export HA_LOG_DIR="/var/log/ssh_dashboard"
export HA_STATE_DIR="/var/lib/ssh_dashboard"
```

### Project Settings

In `.envrc`:
```bash
export SSH_HA_PORT="${SSH_PORT}"
export SSH_MONITOR_PORT="${MONITOR_PORT}"
export SERVICE_LOG_DIR="${HA_LOG_DIR}/service"
```

## Service Files

### SSH HA Service

Location: `lib/ha/ssh-ha.service`
```ini
[Unit]
Description=SSH High Availability Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /opt/ssh_dashboard/lib/ha/failover_manager.sh monitor
Restart=always
```

### SSH Monitor Service

Location: `lib/monitoring/ssh-monitor.service`
```ini
[Unit]
Description=SSH Monitoring Service
After=network.target ssh-ha.service

[Service]
Type=simple
ExecStart=/bin/bash /opt/ssh_dashboard/lib/monitoring/monitor_manager.sh monitor
Restart=on-failure
```

## Best Practices

1. **Security**
   - Use secure paths for keys and certificates
   - Set appropriate file permissions
   - Validate configuration values

2. **Performance**
   - Set reasonable resource limits
   - Configure appropriate check intervals
   - Use efficient logging settings

3. **Reliability**
   - Configure automatic restarts
   - Set up notifications
   - Use health checks

## Related Documentation

- [Service Management Guide](service_management.md)
- [High Availability Guide](high_availability.md)
- [Monitoring Guide](monitoring_configuration.md)

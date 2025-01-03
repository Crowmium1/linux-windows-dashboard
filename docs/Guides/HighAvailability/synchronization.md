# Synchronization Guide

This guide explains how to configure and manage data synchronization between SSH Dashboard Monitor nodes.

## Synchronization Types

### State Synchronization
- Service state
- Configuration files
- SSH keys
- User data

### Data Synchronization
- Monitoring data
- Metrics
- Logs
- Audit records

### Real-time Synchronization
- Active connections
- Session data
- Live metrics
- Events

## Configuration

### Basic Setup
```yaml
synchronization:
  enabled: true
  interval: 300  # seconds
  method: "rsync"  # rsync, lsyncd
  verify: true
```

### Node Configuration
```yaml
nodes:
  primary:
    host: "primary.example.com"
    role: "source"
  secondary:
    host: "secondary.example.com"
    role: "destination"
```

### Path Configuration
```yaml
paths:
  - path: "/etc/ssh"
    priority: "high"
    interval: 300
  
  - path: "${HA_STATE_DIR}"
    priority: "high"
    interval: 300
  
  - path: "${HA_LOG_DIR}"
    priority: "low"
    interval: 3600
```

## Implementation

### Rsync Configuration
```bash
# /etc/rsyncd.conf
[ssh-dashboard]
path = /opt/ssh_dashboard
comment = SSH Dashboard Data
read only = no
auth users = ha-sync
secrets file = /etc/rsyncd.secrets
```

### Lsyncd Configuration
```lua
-- /etc/lsyncd/lsyncd.conf.lua
settings {
    logfile = "/var/log/lsyncd/lsyncd.log",
    statusFile = "/var/log/lsyncd/lsyncd-status.log",
    statusInterval = 20
}

sync {
    default.rsync,
    source = "/opt/ssh_dashboard",
    target = "secondary.example.com:/opt/ssh_dashboard",
    rsync = {
        binary = "/usr/bin/rsync",
        archive = true,
        compress = true,
        whole_file = false
    },
    delay = 5
}
```

## Security

### SSH Keys
```yaml
ssh_keys:
  sync:
    type: "ed25519"
    path: "/root/.ssh/ha_sync"
    permissions: "600"
```

### Authentication
```yaml
authentication:
  method: "key"  # key, password
  user: "ha-sync"
  key_file: "/root/.ssh/ha_sync"
```

### Encryption
```yaml
encryption:
  enabled: true
  method: "ssh"  # ssh, stunnel
  cipher: "aes-256-gcm"
```

## Monitoring

### Sync Status
```bash
# Check sync status
ssh-dashboard-ctl sync status

# View sync logs
tail -f /var/log/ssh-dashboard/sync.log
```

### Health Checks
```yaml
health_checks:
  sync:
    enabled: true
    interval: 300
    checks:
      - type: "file_age"
        path: "${HA_STATE_DIR}/last_sync"
        max_age: 600
      - type: "checksum"
        paths:
          - "/etc/ssh"
          - "${HA_CONFIG_DIR}"
```

## Conflict Resolution

### Strategies
```yaml
conflicts:
  strategy: "newest"  # newest, primary, manual
  resolution:
    automatic: true
    notification: true
```

### Manual Resolution
```bash
# View conflicts
ssh-dashboard-ctl sync conflicts

# Resolve conflicts
ssh-dashboard-ctl sync resolve \
  --path /etc/ssh/config \
  --strategy newest
```

## Performance Tuning

### Bandwidth Control
```yaml
bandwidth:
  limit: "10MB"  # bandwidth limit
  schedule:
    - time: "00:00-06:00"
      limit: "50MB"
    - time: "06:00-18:00"
      limit: "5MB"
```

### Compression
```yaml
compression:
  enabled: true
  level: 6
  algorithm: "zstd"
```

## Recovery

### Sync Recovery
```bash
# Force full sync
ssh-dashboard-ctl sync force

# Verify sync
ssh-dashboard-ctl sync verify

# Fix inconsistencies
ssh-dashboard-ctl sync fix
```

### Backup Before Sync
```yaml
backup:
  enabled: true
  retention: 7
  path: "/var/backups/ssh-dashboard"
```

## Troubleshooting

### Common Issues

1. **Failed Synchronization**
   - Network issues
   - Authentication failure
   - Disk space
   - File permissions

2. **Slow Synchronization**
   - Large files
   - Network bandwidth
   - System resources
   - Configuration issues

### Debug Mode
```bash
# Enable debug logging
ssh-dashboard-ctl sync --debug

# View debug logs
tail -f /var/log/ssh-dashboard/sync-debug.log
```

## Best Practices

1. **Configuration**
   - Regular testing
   - Appropriate intervals
   - Resource monitoring
   - Security measures

2. **Performance**
   - Bandwidth control
   - Compression settings
   - Sync scheduling
   - Resource limits

3. **Maintenance**
   - Regular verification
   - Log rotation
   - Conflict resolution
   - Documentation

## Related Documentation

- [HA Setup](ha_setup.md)
- [Failover](failover.md)
- [Cluster Management](cluster_management.md)
- [Monitoring](../Monitoring/monitoring.md)

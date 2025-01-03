# Backup and Restore Guide

This guide explains how to backup and restore your SSH Dashboard Monitor configuration and data.

## Backup Types

### 1. Configuration Backup
- SSH configuration
- Service settings
- Security policies
- Environment variables

### 2. State Backup
- Service state
- HA state
- Monitoring data
- Security state

### 3. Log Backup
- Service logs
- Security logs
- Monitoring logs
- System logs

## Backup Configuration

```yaml
# config/backup/backup.yaml
backup:
  schedule:
    enabled: true
    interval: "daily"    # daily, weekly, monthly
    time: "00:00"       # 24-hour format
    retention: 7        # days to keep backups
  
  locations:
    local:
      path: "/var/backups/ssh_dashboard"
      enabled: true
    remote:
      enabled: false
      host: "backup.example.com"
      path: "/backups/ssh_dashboard"
      user: "backup"
      key: "/root/.ssh/backup_key"
  
  components:
    config:
      enabled: true
      paths:
        - "/etc/ssh_dashboard"
        - "${HA_CONFIG_DIR}"
    state:
      enabled: true
      paths:
        - "${HA_STATE_DIR}"
    logs:
      enabled: true
      paths:
        - "${HA_LOG_DIR}"
```

## Backup Process

### Manual Backup

```bash
# Full backup
./scripts/backup.sh create full

# Configuration only
./scripts/backup.sh create config

# State only
./scripts/backup.sh create state

# Logs only
./scripts/backup.sh create logs
```

### Automated Backup

1. **Configure Cron Job**
   ```bash
   # /etc/cron.d/ssh-dashboard-backup
   0 0 * * * root /opt/ssh_dashboard/scripts/backup.sh create full
   ```

2. **Configure Systemd Timer**
   ```ini
   # /etc/systemd/system/ssh-dashboard-backup.timer
   [Unit]
   Description=SSH Dashboard Backup Timer
   
   [Timer]
   OnCalendar=daily
   Persistent=true
   
   [Install]
   WantedBy=timers.target
   ```

## Restore Process

### Full Restore

```bash
# List available backups
./scripts/backup.sh list

# Restore from specific backup
./scripts/backup.sh restore <backup-id>
```

### Selective Restore

```bash
# Restore configuration only
./scripts/backup.sh restore <backup-id> --component config

# Restore state only
./scripts/backup.sh restore <backup-id> --component state

# Restore specific files
./scripts/backup.sh restore <backup-id> --files "path/to/file"
```

## Verification

### Backup Verification

```bash
# Verify backup integrity
./scripts/backup.sh verify <backup-id>

# Test restore in isolation
./scripts/backup.sh test-restore <backup-id>
```

### Post-Restore Verification

1. **Check Service Status**
   ```bash
   systemctl status ssh-ha
   systemctl status ssh-monitor
   ```

2. **Verify Configuration**
   ```bash
   ./scripts/verify-config.sh
   ```

3. **Check Data Integrity**
   ```bash
   ./scripts/verify-data.sh
   ```

## Best Practices

1. **Backup Strategy**
   - Regular automated backups
   - Multiple backup locations
   - Encryption for sensitive data
   - Retention policy

2. **Security**
   - Secure backup storage
   - Encrypted transfers
   - Access control
   - Audit logging

3. **Testing**
   - Regular restore tests
   - Integrity verification
   - Documentation updates
   - Recovery procedures

## Troubleshooting

### Common Issues

1. **Backup Failed**
   - Check disk space
   - Verify permissions
   - Check network connectivity
   - Review backup logs

2. **Restore Failed**
   - Verify backup integrity
   - Check system compatibility
   - Review restore logs
   - Check dependencies

### Recovery Steps

1. **Failed Backup**
   ```bash
   # Check backup logs
   tail -f ${HA_LOG_DIR}/backup.log
   
   # Verify backup space
   df -h
   
   # Check backup permissions
   ls -l /var/backups/ssh_dashboard
   ```

2. **Failed Restore**
   ```bash
   # Check restore logs
   tail -f ${HA_LOG_DIR}/restore.log
   
   # Verify backup
   ./scripts/backup.sh verify <backup-id>
   
   # Clean temporary files
   ./scripts/backup.sh cleanup
   ```

## Related Documentation

- [Service Management Guide](service_management.md)
- [Configuration Guide](configuration.md)
- [Troubleshooting Guide](troubleshooting.md)

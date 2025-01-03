# Backup Guide

This guide explains how to configure and manage backups in SSH Dashboard Monitor.

## Backup Types

### System Backup
- Configuration files
- User data
- SSH keys
- Logs

### Data Backup
- Monitoring data
- Metrics
- Audit logs
- Custom data

### State Backup
- Service state
- Session data
- Cache data
- Temporary files

## Configuration

### Basic Setup
```yaml
backup:
  enabled: true
  schedule: "0 0 * * *"  # daily
  retention: 7  # days
  compression: true
```

### Backup Locations
```yaml
locations:
  local:
    path: "/backup/ssh-dashboard"
    type: "local"
    
  remote:
    path: "s3://backup/ssh-dashboard"
    type: "s3"
    region: "us-west-2"
```

## Implementation

### Local Backup
```bash
# Create backup
ssh-dashboard-ctl backup create \
  --type full \
  --location local

# List backups
ssh-dashboard-ctl backup list \
  --location local

# Restore backup
ssh-dashboard-ctl backup restore \
  --location local \
  --id backup-20250103
```

### Cloud Backup
```yaml
cloud_backup:
  provider: "aws"  # aws, gcp, azure
  
  aws:
    bucket: "ssh-dashboard-backup"
    region: "us-west-2"
    credentials:
      access_key: "your-access-key"
      secret_key: "your-secret-key"
```

## Backup Strategy

### Full Backup
```yaml
full_backup:
  schedule: "0 0 * * 0"  # weekly
  retention: 4  # weeks
  
  paths:
    - "/etc/ssh-dashboard"
    - "/var/lib/ssh-dashboard"
    - "/var/log/ssh-dashboard"
```

### Incremental Backup
```yaml
incremental_backup:
  schedule: "0 0 * * 1-6"  # daily except Sunday
  retention: 7  # days
  base: "latest_full"
```

## Encryption

### Backup Encryption
```yaml
encryption:
  enabled: true
  algorithm: "aes-256-gcm"
  key_file: "/etc/ssh-dashboard/backup.key"
```

### Key Management
```yaml
key_management:
  rotation: 90  # days
  backup: true
  storage:
    type: "vault"
    path: "secret/backup-keys"
```

## Monitoring

### Backup Status
```yaml
monitoring:
  backup:
    enabled: true
    metrics:
      - "backup_size"
      - "backup_duration"
      - "backup_status"
```

### Alerts
```yaml
alerts:
  backup:
    failed:
      severity: "critical"
      notify: ["email", "slack"]
    
    size_increase:
      threshold: 50  # percent
      severity: "warning"
```

## Recovery

### Recovery Testing
```yaml
recovery_testing:
  schedule: "0 0 1 * *"  # monthly
  environment: "test"
  verify: true
```

### Disaster Recovery
```yaml
disaster_recovery:
  plan:
    - "stop_services"
    - "restore_backup"
    - "verify_data"
    - "start_services"
```

## Automation

### Backup Automation
```yaml
automation:
  pre_backup:
    - name: "stop_services"
      command: "ssh-dashboard-ctl service stop"
    
  post_backup:
    - name: "start_services"
      command: "ssh-dashboard-ctl service start"
    
  on_failure:
    - name: "notify_admin"
      command: "ssh-dashboard-ctl notify backup_failed"
```

### Cleanup
```yaml
cleanup:
  enabled: true
  rules:
    - type: "age"
      max_age: 30  # days
    - type: "count"
      max_count: 10
    - type: "size"
      max_size: "100GB"
```

## Integration

### S3 Integration
```yaml
s3:
  bucket: "ssh-dashboard-backup"
  region: "us-west-2"
  path: "backups/"
  
  lifecycle:
    enabled: true
    rules:
      - prefix: "daily/"
        expiration: 7
      - prefix: "weekly/"
        expiration: 30
```

### Notification Integration
```yaml
notifications:
  email:
    enabled: true
    recipients:
      - "admin@example.com"
  
  slack:
    enabled: true
    webhook: "https://hooks.slack.com/services/xxx/yyy/zzz"
    channel: "#backups"
```

## Best Practices

1. **Backup Strategy**
   - Regular backups
   - Multiple locations
   - Encryption
   - Testing

2. **Monitoring**
   - Status monitoring
   - Size tracking
   - Error alerting
   - Performance metrics

3. **Recovery**
   - Regular testing
   - Documentation
   - Access control
   - Verification

## Related Documentation

- [Restore Guide](restore.md)
- [Disaster Recovery](disaster_recovery.md)
- [Monitoring Guide](../Monitoring/monitoring.md)
- [Security Guide](../Security/security_configuration.md)

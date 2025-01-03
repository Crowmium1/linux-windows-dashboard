# SSH Dashboard High Availability Guide

This guide explains the high availability features of the SSH Dashboard, including failover management and state synchronization.

## Table of Contents
1. [Overview](#overview)
2. [Configuration](#configuration)
3. [Failover Management](#failover-management)
4. [State Synchronization](#state-synchronization)
5. [Installation](#installation)
6. [Troubleshooting](#troubleshooting)

## Overview

The SSH Dashboard's high availability system consists of two main components:

1. **Failover Manager**: Handles automatic failover between primary and backup SSH hosts
2. **State Synchronization**: Ensures configuration and state consistency across hosts

## Configuration

### Environment Variables
Create or modify `.envrc` file in the project root:
```bash
# High Availability Settings
export SSH_HA_PRIMARY_HOST="primary.example.com"
export SSH_HA_PRIMARY_PORT=22
export SSH_HA_CHECK_INTERVAL=30
export SSH_HA_MAX_FAILURES=3

# Backup Hosts (comma-separated)
export SSH_HA_BACKUP_HOSTS="backup1.example.com,backup2.example.com"
export SSH_HA_BACKUP_PORTS="22,22"
export SSH_HA_BACKUP_PRIORITIES="1,2"

# Sync Settings
export SSH_HA_SYNC_INTERVAL=60
export SSH_HA_SYNC_PATHS="/etc/ssh,/var/log/ssh"
export SSH_HA_SYNC_EXCLUDE="*.tmp,*.bak"

# Notification Settings
export SSH_HA_NOTIFY_EMAIL="admin@example.com"
export SSH_HA_NOTIFY_SLACK_WEBHOOK=""
export SSH_HA_NOTIFY_SLACK_CHANNEL="#ssh-alerts"
```

### Failover Configuration
The system uses `config/ha/failover.yaml` for detailed configuration:
```yaml
hosts:
  primary:
    hostname: ${SSH_HA_PRIMARY_HOST}
    port: ${SSH_HA_PRIMARY_PORT}
    check_interval: ${SSH_HA_CHECK_INTERVAL}
    max_failures: ${SSH_HA_MAX_FAILURES}
    
  backup:
    - hostname: backup1.example.com
      port: 22
      priority: 1

failover:
  auto_failover: true
  failback_delay: 300
  require_manual_failback: false
```

## Failover Management

### Starting Failover Monitor
```bash
./lib/ha/failover_manager.sh monitor
```

### Checking Status
```bash
./lib/ha/failover_manager.sh status
```

### Manual Failover
```bash
./lib/ha/failover_manager.sh failover backup1.example.com
```

### Health Checks
The system performs several health checks:
1. **Connection Health**: SSH connectivity test
2. **Service Health**: Required service status
3. **Resource Health**: CPU, memory, and disk usage

## State Synchronization

### Starting Sync Monitor
```bash
./lib/ha/state_sync.sh monitor
```

### Manual Sync
```bash
# Sync all hosts
./lib/ha/state_sync.sh sync

# Sync specific hosts
./lib/ha/state_sync.sh sync primary.example.com backup1.example.com
```

### Verifying Sync
```bash
./lib/ha/state_sync.sh verify primary.example.com backup1.example.com
```

### Sync Status
```bash
./lib/ha/state_sync.sh status
```

## Installation

1. **Set Up Environment**:
   ```bash
   # Load environment variables
   source .envrc
   ```

2. **Install Service**:
   ```bash
   # Copy service file
   sudo cp lib/ha/ssh-ha.service /etc/systemd/system/
   
   # Reload systemd
   sudo systemctl daemon-reload
   
   # Enable and start service
   sudo systemctl enable ssh-ha
   sudo systemctl start ssh-ha
   ```

3. **Configure SSH Keys**:
   ```bash
   # Generate SSH key if needed
   ssh-keygen -t ed25519 -f ~/.ssh/ha_key
   
   # Copy to backup hosts
   ssh-copy-id -i ~/.ssh/ha_key.pub backup1.example.com
   ssh-copy-id -i ~/.ssh/ha_key.pub backup2.example.com
   ```

## Troubleshooting

### Common Issues

1. **Failover Not Working**
   - Check network connectivity
   - Verify SSH key permissions
   - Check service status on all hosts
   ```bash
   ./failover_manager.sh status
   systemctl status ssh-ha
   ```

2. **Sync Failures**
   - Check disk space
   - Verify file permissions
   - Check rsync logs
   ```bash
   ./state_sync.sh verify source_host target_host
   ```

3. **Service Not Starting**
   - Check systemd logs
   ```bash
   journalctl -u ssh-ha -f
   ```

### Logs

Important log files:
- Failover logs: `/var/log/ssh_dashboard/failover.log`
- Sync logs: `/var/log/ssh_dashboard/sync.log`
- Service logs: `journalctl -u ssh-ha`

### Recovery Steps

1. **Manual Recovery**:
   ```bash
   # Stop automatic failover
   sudo systemctl stop ssh-ha
   
   # Check all hosts
   ./failover_manager.sh status
   
   # Force failover if needed
   ./failover_manager.sh failover target_host
   
   # Restart automatic failover
   sudo systemctl start ssh-ha
   ```

2. **State Recovery**:
   ```bash
   # Force full sync
   ./state_sync.sh sync primary_host backup_host
   
   # Verify sync
   ./state_sync.sh verify primary_host backup_host
   ```

## Best Practices

1. **Testing**:
   - Regularly test failover functionality
   - Verify sync integrity
   - Practice recovery procedures

2. **Monitoring**:
   - Monitor failover service status
   - Check sync status regularly
   - Review logs for issues

3. **Maintenance**:
   - Keep SSH keys up to date
   - Rotate logs regularly
   - Update configuration as needed

4. **Security**:
   - Use secure SSH key types (ed25519)
   - Restrict SSH access to necessary hosts
   - Monitor failed access attempts

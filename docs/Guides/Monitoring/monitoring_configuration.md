# SSH Service Monitoring Guide

This guide explains how to configure and use the monitoring system for the SSH Dashboard Monitor.

## Overview

The monitoring system provides comprehensive oversight of:
- SSH service health
- Host availability
- System resources
- Service states
- Automated notifications

## Configuration Levels

### 1. Environment Variables (`~/.config/direnv/global.envrc`)

```bash
# Resource Thresholds
export RESOURCE_CPU_THRESHOLD=80    # CPU usage percentage threshold
export RESOURCE_MEM_THRESHOLD=90    # Memory usage percentage threshold
export RESOURCE_DISK_THRESHOLD=85   # Disk usage percentage threshold
export MONITOR_CHECK_INTERVAL=60    # Monitoring check interval in seconds
```

### 2. YAML Configuration (`config/ha/failover.yaml`)

```yaml
# Health checks configuration
health_check:
  connection:
    timeout: 5
    retries: 3
  
  services:
    - name: "sshd"
      required: true
    - name: "ssh-agent"
      required: false

# Notification settings
notifications:
  enabled: true
  channels:
    - type: "email"
      recipients: ["admin@example.com"]
    - type: "slack"
      webhook: "https://hooks.slack.com/services/..."
      channel: "#ssh-alerts"
```

## Monitoring Components

### 1. Host Monitoring

Checks performed on each host:
- SSH connectivity
- Service availability
- Resource utilization
- Overall health status

Status Categories:
- `healthy`: All checks pass
- `degraded`: Some non-critical issues
- `unreachable`: Host cannot be contacted
- `resource_warning`: Resource thresholds exceeded

### 2. Service Monitoring

Service checks include:
- Service running status
- Required vs optional services
- Service dependencies
- Startup state

Service States:
- `active`: Service is running
- `inactive`: Service is stopped
- `failed`: Service failed to start
- `unknown`: Status cannot be determined

### 3. Resource Monitoring

Resources monitored:
- CPU usage (percentage)
- Memory utilization (percentage)
- Disk space usage (percentage)

Thresholds:
- Configurable via environment variables
- Different levels for different resources
- Customizable per environment

### 4. Notification System

Notification channels:
- Email alerts
- Slack messages
- Configurable recipients
- Custom alert thresholds

Alert Types:
- Host unreachable
- Service failure
- Resource warnings
- Recovery notifications

## Usage

### Basic Monitoring

```bash
# Check all hosts
./monitor_manager.sh check

# Check specific host
./monitor_manager.sh check hostname

# View current status
./monitor_manager.sh status

# Start continuous monitoring
./monitor_manager.sh monitor
```

### Status Reports

The status report includes:
```
Monitoring Status Report
Last check: 2025-01-03 08:15:28
Check interval: 60 seconds

Host Status:
  primary.example.com: healthy
    Resources: healthy
  backup1.example.com: degraded
    Resources: cpu_high

Service Status:
  primary.example.com.sshd: active
  backup1.example.com.sshd: active
  backup1.example.com.ssh-agent: inactive
```

## Best Practices

1. **Resource Thresholds**
   - Set appropriate thresholds for your environment
   - Consider host capabilities
   - Allow headroom for spikes

2. **Service Monitoring**
   - Mark critical services as required
   - Set appropriate retry counts
   - Configure meaningful timeouts

3. **Notifications**
   - Configure multiple notification channels
   - Set appropriate alert intervals
   - Use meaningful alert messages

4. **Maintenance**
   - Regularly review monitoring logs
   - Adjust thresholds as needed
   - Update notification settings

## Troubleshooting

Common issues and solutions:

1. **False Positives**
   - Check threshold settings
   - Verify service dependencies
   - Review network connectivity

2. **Missing Notifications**
   - Verify notification configuration
   - Check notification service access
   - Validate recipient settings

3. **Resource Alerts**
   - Review resource usage patterns
   - Check for resource leaks
   - Adjust thresholds if needed

## Related Documentation

- [High Availability Guide](high_availability.md)
- [State Synchronization Guide](state_sync.md)
- [Security Best Practices](security.md)

## Monitoring Directory Structure

```
lib/monitoring/
├── monitor_manager.sh    # Main monitoring script
└── plugins/             # Custom monitoring plugins

logs/monitor/
├── alerts/              # Alert history
├── status/              # Status history
└── metrics/             # Resource metrics

config/ha/
└── failover.yaml        # Monitoring configuration
```

## Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `RESOURCE_CPU_THRESHOLD` | CPU usage threshold (%) | 80 |
| `RESOURCE_MEM_THRESHOLD` | Memory usage threshold (%) | 90 |
| `RESOURCE_DISK_THRESHOLD` | Disk usage threshold (%) | 85 |
| `MONITOR_CHECK_INTERVAL` | Check interval (seconds) | 60 |
| `HA_LOG_DIR` | Log directory path | ~/.ssh_dashboard/logs |
| `HA_STATE_DIR` | State directory path | ~/.ssh_dashboard/state |

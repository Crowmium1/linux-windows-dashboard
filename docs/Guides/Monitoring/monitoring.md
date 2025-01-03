# SSH Dashboard Monitoring Guide

This guide provides detailed information about the SSH Dashboard's monitoring system, including alerts, metrics collection, and resource tracking.

## Table of Contents
1. [Overview](#overview)
2. [Configuration](#configuration)
3. [Alert Management](#alert-management)
4. [Metrics Collection](#metrics-collection)
5. [Resource Tracking](#resource-tracking)
6. [Integration](#integration)
7. [Best Practices](#best-practices)

## Overview

The SSH Dashboard monitoring system consists of three main components:

1. **Alert Management**: Handles notifications for various events and threshold violations
2. **Metrics Collection**: Gathers and stores performance and health metrics
3. **Resource Tracking**: Monitors and manages system resources

Each component can work independently or integrate with others to provide comprehensive monitoring.

## Configuration

All configuration files are located in `config/monitoring/`:

### Alert Configuration (`alerts.yaml`)
```yaml
notification_channels:
  email:
    enabled: true
    smtp_server: "smtp.example.com"
    # ... other email settings
  slack:
    enabled: false
    webhook_url: ""
    # ... other Slack settings

thresholds:
  connection:
    latency_ms: 1000
    failed_attempts: 5
  # ... other thresholds
```

### Metrics Configuration (`metrics.yaml`)
```yaml
collection:
  interval_sec: 60
  batch_size: 100

metrics:
  connection:
    enabled: true
    measurements:
      - latency
      - packet_loss
  # ... other metric settings
```

### Resource Configuration (`resources.yaml`)
```yaml
limits:
  process:
    max_cpu_percent: 80
    max_memory_mb: 1024
  # ... other resource limits
```

## Alert Management

The alert system (`alerts.sh`) provides:

- Multiple notification channels (email, Slack)
- Threshold-based alerting
- Alert history management

### Usage Examples

1. Check connection status:
```bash
./alerts.sh check-connection 150 5  # 150ms latency, 5 failed attempts
```

2. Monitor service status:
```bash
./alerts.sh check-service sshd active 2  # service name, status, restart count
```

### Alert Types

1. **Connection Alerts**
   - High latency
   - Failed connection attempts
   - Connection timeouts

2. **Service Alerts**
   - Service down
   - High restart count
   - Configuration changes

## Metrics Collection

The metrics system (`metrics.sh`) collects:

### Connection Metrics
- Latency
- Packet loss
- Bandwidth usage
- Active connections

### System Metrics
- CPU usage
- Memory usage
- Disk usage
- Network I/O

### Service Metrics
- Service status
- Uptime
- Restart count
- Resource usage

### Usage Examples

1. Collect connection metrics:
```bash
./metrics.sh collect connection server1.example.com
```

2. Collect system metrics:
```bash
./metrics.sh collect system
```

3. Export metrics:
```bash
./metrics.sh export
```

### Storage Backends

Metrics can be stored in:
- Files (CSV/JSON)
- SQLite database
- Prometheus

## Resource Tracking

The resource tracker (`resource_tracker.sh`) provides:

### Process Monitoring
- CPU usage
- Memory usage
- File handles
- Thread count

### Connection Resources
- Concurrent connections
- Per-host connections
- Bandwidth usage

### Storage Management
- Log rotation
- Metrics storage
- Temporary file cleanup

### Usage Examples

1. Start continuous monitoring:
```bash
./resource_tracker.sh monitor
```

2. Check specific process:
```bash
./resource_tracker.sh check process 1234
```

3. Manual cleanup:
```bash
./resource_tracker.sh cleanup
```

## Integration

The monitoring components can integrate with each other:

1. **Resource Tracker → Alerts**
   - Triggers alerts when resource thresholds are exceeded
   - Sends notifications for cleanup events

2. **Metrics → Alerts**
   - Uses metric data to determine alert conditions
   - Provides historical context for alerts

3. **Resource Tracker → Metrics**
   - Feeds resource usage data into metrics collection
   - Helps track resource utilization trends

## Best Practices

1. **Alert Configuration**
   - Set appropriate thresholds to avoid alert fatigue
   - Configure multiple notification channels for redundancy
   - Regularly review and update alert rules

2. **Metrics Collection**
   - Adjust collection intervals based on system load
   - Use appropriate storage backend for your scale
   - Implement data retention policies

3. **Resource Management**
   - Set conservative resource limits initially
   - Monitor resource usage patterns before adjusting limits
   - Configure automatic cleanup to prevent disk space issues

4. **General Tips**
   - Regularly backup configuration files
   - Test notification channels periodically
   - Document any custom thresholds or configurations
   - Monitor the monitoring system itself

## Troubleshooting

Common issues and solutions:

1. **Missing Alerts**
   - Check notification channel configuration
   - Verify threshold settings
   - Check alert history logs

2. **High Resource Usage**
   - Adjust collection intervals
   - Review storage backend configuration
   - Check cleanup policies

3. **Storage Issues**
   - Verify disk space
   - Check file permissions
   - Review retention policies

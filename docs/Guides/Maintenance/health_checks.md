# Health Checks Guide

This guide explains how to implement and manage health checks in the SSH Dashboard Monitor.

## Health Check Types

### System Health
- CPU usage
- Memory usage
- Disk space
- Network connectivity

### Service Health
- SSH service
- Monitoring service
- Dashboard service
- HA service

### Security Health
- SSH key status
- Authentication logs
- Access control
- Encryption status

## Configuration

### Basic Setup
```yaml
health_checks:
  enabled: true
  interval: 60
  timeout: 5
  retries: 3
```

### Check Configuration
```yaml
checks:
  system:
    cpu:
      warning: 80
      critical: 90
      interval: 30
    memory:
      warning: 80
      critical: 90
      interval: 30
    disk:
      warning: 80
      critical: 90
      interval: 300
  
  services:
    ssh:
      port: 22
      type: "tcp"
      interval: 30
    dashboard:
      url: "http://localhost:3000/health"
      type: "http"
      interval: 30
```

## Implementation

### System Checks

```bash
#!/bin/bash
# check_system.sh

# Check CPU
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
if [ $(echo "$cpu_usage > 90" | bc) -eq 1 ]; then
    echo "CRITICAL: CPU usage at ${cpu_usage}%"
    exit 2
fi

# Check Memory
mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
if [ $(echo "$mem_usage > 90" | bc) -eq 1 ]; then
    echo "CRITICAL: Memory usage at ${mem_usage}%"
    exit 2
fi

# Check Disk
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 90 ]; then
    echo "CRITICAL: Disk usage at ${disk_usage}%"
    exit 2
fi

echo "OK: System health checks passed"
exit 0
```

### Service Checks

```python
# check_services.py
import socket
import requests
import sys

def check_tcp(host, port, timeout=5):
    try:
        sock = socket.socket()
        sock.settimeout(timeout)
        sock.connect((host, port))
        return True
    except:
        return False
    finally:
        sock.close()

def check_http(url, timeout=5):
    try:
        response = requests.get(url, timeout=timeout)
        return response.status_code == 200
    except:
        return False

def main():
    # Check SSH
    if not check_tcp('localhost', 22):
        print("CRITICAL: SSH service not responding")
        sys.exit(2)
    
    # Check Dashboard
    if not check_http('http://localhost:3000/health'):
        print("CRITICAL: Dashboard not responding")
        sys.exit(2)
    
    print("OK: Service checks passed")
    sys.exit(0)

if __name__ == '__main__':
    main()
```

## Monitoring

### Status Check
```bash
# Check all health
ssh-dashboard-ctl health check

# Check specific component
ssh-dashboard-ctl health check --component system
ssh-dashboard-ctl health check --component services
```

### Health Status
```bash
# View health status
ssh-dashboard-ctl health status

# View health history
ssh-dashboard-ctl health history
```

## Alerting

### Configuration
```yaml
alerts:
  email:
    enabled: true
    recipients:
      - "admin@example.com"
  slack:
    enabled: true
    webhook: "https://hooks.slack.com/services/xxx/yyy/zzz"
    channel: "#alerts"
```

### Alert Rules
```yaml
rules:
  - name: "high_cpu"
    condition: "cpu > 90"
    duration: "5m"
    severity: "critical"
  
  - name: "service_down"
    condition: "service.status == 'down'"
    duration: "1m"
    severity: "critical"
```

## Recovery Actions

### Automatic Recovery
```yaml
recovery:
  enabled: true
  actions:
    service_restart:
      condition: "service.status == 'down'"
      command: "systemctl restart {service}"
      max_attempts: 3
    
    disk_cleanup:
      condition: "disk > 90"
      command: "/opt/ssh_dashboard/scripts/cleanup.sh"
      max_attempts: 1
```

### Manual Recovery
```bash
# Restart service
ssh-dashboard-ctl service restart ssh

# Clean disk space
ssh-dashboard-ctl maintenance cleanup-disk
```

## Reporting

### Health Reports
```bash
# Generate health report
ssh-dashboard-ctl report generate --type health

# View report
ssh-dashboard-ctl report view --latest
```

### Metrics
- Check duration
- Success rate
- Error frequency
- Recovery time

## Troubleshooting

### Common Issues

1. **Failed Checks**
   - Resource exhaustion
   - Service crashes
   - Network issues
   - Configuration errors

2. **False Positives**
   - Threshold tuning
   - Check timing
   - Network latency
   - Resource spikes

### Debug Mode
```bash
# Enable debug logging
ssh-dashboard-ctl health check --debug

# View debug logs
tail -f /var/log/ssh-dashboard/health.log
```

## Best Practices

1. **Configuration**
   - Appropriate intervals
   - Realistic thresholds
   - Proper timeouts
   - Meaningful alerts

2. **Monitoring**
   - Regular checks
   - Trend analysis
   - Alert verification
   - Performance impact

3. **Maintenance**
   - Regular review
   - Threshold adjustments
   - Alert tuning
   - Documentation updates

## Related Documentation

- [Monitoring Guide](../Monitoring/monitoring.md)
- [Service Management](../CoreServices/service_management.md)
- [Troubleshooting](troubleshooting.md)
- [Alerting](../Monitoring/alerting.md)

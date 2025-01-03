# Failover Guide

This guide explains how to configure and manage failover in the SSH Dashboard Monitor.

## Failover Architecture

### Components
- Primary Node
- Secondary Node
- Virtual IP
- Health Monitoring
- State Synchronization

### States
1. **Normal Operation**
   - Primary active
   - Secondary standby
   - Services synchronized

2. **Failover Mode**
   - Primary failed
   - Secondary promoted
   - Services migrated

3. **Recovery Mode**
   - Primary restored
   - State synchronized
   - Services rebalanced

## Configuration

### Basic Setup
```yaml
failover:
  enabled: true
  check_interval: 30
  max_failures: 3
  auto_failback: true
```

### Node Configuration
```yaml
nodes:
  primary:
    host: "primary.example.com"
    ip: "192.168.1.10"
    priority: 100
  secondary:
    host: "secondary.example.com"
    ip: "192.168.1.11"
    priority: 90
```

### Virtual IP
```yaml
virtual_ip:
  address: "192.168.1.100"
  interface: "eth0"
  mask: "24"
```

## Failover Process

### Automatic Failover

1. **Detection**
   - Health check failure
   - Resource exhaustion
   - Network partition

2. **Transition**
   - Stop primary services
   - Release virtual IP
   - Promote secondary

3. **Recovery**
   - Restore services
   - Synchronize state
   - Update routing

### Manual Failover

```bash
# Initiate failover
ssh-dashboard-ctl failover initiate

# Check failover status
ssh-dashboard-ctl failover status

# Cancel failover
ssh-dashboard-ctl failover cancel
```

## Health Monitoring

### Health Checks
```yaml
health_check:
  services:
    - name: "ssh"
      type: "tcp"
      port: 22
    - name: "dashboard"
      type: "http"
      url: "http://localhost:3000/health"
```

### Thresholds
```yaml
thresholds:
  response_time: 5
  failure_count: 3
  recovery_time: 60
```

## State Synchronization

### Data Sync
```yaml
sync:
  interval: 300
  paths:
    - "/etc/ssh"
    - "/var/lib/ssh-dashboard"
  exclude:
    - "*.tmp"
    - "*.log"
```

### Service Sync
```yaml
services:
  sync:
    - name: "sshd"
      config: "/etc/ssh/sshd_config"
    - name: "dashboard"
      config: "/etc/ssh-dashboard/config"
```

## Network Configuration

### Keepalive
```yaml
keepalive:
  interval: 2
  timeout: 5
  max_failures: 3
```

### Firewall Rules
```bash
# Allow HA communication
iptables -A INPUT -p tcp --dport 873 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

## Monitoring

### Status Check
```bash
# Check HA status
ssh-dashboard-ctl ha status

# View sync status
ssh-dashboard-ctl ha sync-status

# Check node health
ssh-dashboard-ctl ha health
```

### Logging
```bash
# View HA logs
tail -f /var/log/ssh-dashboard/ha.log

# View failover events
ssh-dashboard-ctl ha events
```

## Troubleshooting

### Common Issues

1. **Split Brain**
   - Network partition
   - Dual primary
   - Inconsistent state

2. **Failed Failover**
   - Service stuck
   - IP conflict
   - State mismatch

3. **Sync Issues**
   - Network problems
   - Disk space
   - Permission errors

### Recovery Steps

1. **Manual Recovery**
   ```bash
   # Stop all services
   ssh-dashboard-ctl stop all

   # Reset state
   ssh-dashboard-ctl ha reset

   # Restart services
   ssh-dashboard-ctl start all
   ```

2. **Force Primary**
   ```bash
   # Force node as primary
   ssh-dashboard-ctl ha force-primary
   ```

## Best Practices

1. **Configuration**
   - Regular testing
   - Documented procedures
   - Monitored health checks
   - Automated recovery

2. **Networking**
   - Redundant connections
   - Monitored links
   - Proper firewall rules
   - Network isolation

3. **Maintenance**
   - Regular testing
   - Updated documentation
   - Monitored metrics
   - Backup procedures

## Related Documentation

- [HA Setup](ha_setup.md)
- [Synchronization](synchronization.md)
- [Cluster Management](cluster_management.md)
- [Monitoring](../Monitoring/monitoring.md)

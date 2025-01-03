# Cluster Management Guide

This guide explains how to manage and maintain SSH Dashboard Monitor clusters.

## Cluster Architecture

### Components
- Primary node
- Secondary nodes
- Load balancer
- Shared storage
- Service discovery

### Topology Types
1. Active-Passive
2. Active-Active
3. Multi-Region
4. Hybrid

## Configuration

### Basic Setup
```yaml
cluster:
  name: "ssh-dashboard"
  mode: "active-passive"  # active-passive, active-active
  nodes:
    - host: "node1.example.com"
      role: "primary"
      datacenter: "dc1"
    - host: "node2.example.com"
      role: "secondary"
      datacenter: "dc1"
```

### Network Configuration
```yaml
network:
  virtual_ip: "192.168.1.100"
  interface: "eth0"
  subnet: "192.168.1.0/24"
  
  keepalive:
    interval: 2
    timeout: 5
    max_failures: 3
```

## Node Management

### Adding Nodes
```bash
# Add new node
ssh-dashboard-ctl cluster add-node \
  --host node3.example.com \
  --role secondary \
  --datacenter dc1

# Initialize node
ssh-dashboard-ctl cluster init-node \
  --host node3.example.com
```

### Removing Nodes
```bash
# Drain node
ssh-dashboard-ctl cluster drain \
  --host node3.example.com

# Remove node
ssh-dashboard-ctl cluster remove-node \
  --host node3.example.com
```

## Service Discovery

### Configuration
```yaml
discovery:
  enabled: true
  provider: "consul"  # consul, etcd, zookeeper
  
  consul:
    host: "localhost"
    port: 8500
    datacenter: "dc1"
```

### Service Registration
```yaml
services:
  - name: "ssh-dashboard"
    port: 3000
    check:
      type: "http"
      path: "/health"
      interval: "10s"
```

## Load Balancing

### Configuration
```yaml
load_balancer:
  enabled: true
  type: "nginx"  # nginx, haproxy
  algorithm: "round-robin"
  
  health_check:
    path: "/health"
    interval: 5
    timeout: 3
    max_failures: 3
```

### SSL Termination
```yaml
ssl:
  enabled: true
  cert: "/etc/ssl/certs/dashboard.crt"
  key: "/etc/ssl/private/dashboard.key"
  protocols:
    - "TLSv1.2"
    - "TLSv1.3"
```

## State Management

### Shared State
```yaml
state:
  type: "distributed"  # local, distributed
  provider: "redis"  # redis, etcd
  
  redis:
    host: "redis.example.com"
    port: 6379
    password: "password"
```

### Session Management
```yaml
sessions:
  store: "redis"
  ttl: 3600
  prefix: "ssh-dashboard:"
```

## Monitoring

### Cluster Health
```bash
# Check cluster health
ssh-dashboard-ctl cluster health

# View node status
ssh-dashboard-ctl cluster status

# Check sync status
ssh-dashboard-ctl cluster sync-status
```

### Metrics
```yaml
metrics:
  cluster:
    enabled: true
    interval: 60
    collectors:
      - "node_status"
      - "sync_status"
      - "service_health"
```

## Maintenance

### Rolling Updates
```bash
# Start rolling update
ssh-dashboard-ctl cluster update \
  --version 1.2.0 \
  --batch-size 1 \
  --pause-time 300

# Rollback update
ssh-dashboard-ctl cluster rollback \
  --version 1.1.0
```

### Backup Management
```yaml
backup:
  enabled: true
  schedule: "0 0 * * *"
  retention: 7
  locations:
    - path: "/backup/cluster"
      type: "local"
    - path: "s3://backup/cluster"
      type: "s3"
```

## Disaster Recovery

### Recovery Plans
```yaml
recovery:
  plans:
    node_failure:
      actions:
        - "promote_secondary"
        - "rebuild_failed"
      automatic: true
    
    datacenter_failure:
      actions:
        - "activate_dr_site"
        - "update_dns"
      automatic: false
```

### Failover Configuration
```yaml
failover:
  automatic: true
  check_interval: 30
  max_failures: 3
  recovery_timeout: 300
```

## Security

### Network Security
```yaml
security:
  encryption:
    enabled: true
    protocol: "tls"
    verify_peers: true
  
  firewall:
    enabled: true
    allowed_networks:
      - "192.168.1.0/24"
      - "10.0.0.0/8"
```

### Authentication
```yaml
authentication:
  type: "mutual-tls"
  ca_cert: "/etc/ssl/ca.crt"
  node_cert: "/etc/ssl/node.crt"
  node_key: "/etc/ssl/node.key"
```

## Troubleshooting

### Common Issues

1. **Split Brain**
   - Network partition
   - Inconsistent state
   - Multiple primaries

2. **Sync Issues**
   - Network problems
   - Disk space
   - Permission errors

### Debug Mode
```bash
# Enable debug logging
ssh-dashboard-ctl cluster --debug

# View debug logs
tail -f /var/log/ssh-dashboard/cluster-debug.log
```

## Best Practices

1. **Architecture**
   - Proper sizing
   - Network isolation
   - Redundancy
   - Monitoring

2. **Operations**
   - Regular testing
   - Documented procedures
   - Automated recovery
   - Performance tuning

3. **Security**
   - Network security
   - Authentication
   - Encryption
   - Access control

## Related Documentation

- [HA Setup](ha_setup.md)
- [Synchronization](synchronization.md)
- [Failover](failover.md)
- [Monitoring](../Monitoring/monitoring.md)

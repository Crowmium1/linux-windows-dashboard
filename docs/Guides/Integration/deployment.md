# Deployment Guide

This guide explains how to deploy the SSH Dashboard Monitor in various environments.

## Deployment Types

### 1. Single Server
- All components on one server
- Suitable for testing/development
- Limited high availability

### 2. High Availability
- Multiple servers
- Load balancing
- Automatic failover
- Data replication

### 3. Distributed
- Components across servers
- Service discovery
- Centralized management
- Scalable architecture

## Prerequisites

### System Requirements

```yaml
# Minimum Requirements
hardware:
  cpu: 2 cores
  memory: 4GB
  disk: 20GB
  network: 1Gbps

# Recommended Requirements
hardware:
  cpu: 4 cores
  memory: 8GB
  disk: 50GB
  network: 10Gbps
```

### Software Requirements

```yaml
software:
  os:
    - Ubuntu 20.04+
    - CentOS 8+
    - RHEL 8+
  packages:
    - openssh-server
    - rsync
    - systemd
    - nodejs
    - npm
```

## Deployment Steps

### 1. Single Server

1. **Prepare System**
   ```bash
   # Update system
   apt update && apt upgrade -y
   
   # Install dependencies
   apt install -y openssh-server rsync nodejs npm
   ```

2. **Install Application**
   ```bash
   # Clone repository
   git clone <repository-url> /opt/ssh_dashboard
   
   # Install dependencies
   cd /opt/ssh_dashboard
   npm install
   ```

3. **Configure Services**
   ```bash
   # Copy service files
   cp lib/ha/ssh-ha.service /etc/systemd/system/
   cp lib/monitoring/ssh-monitor.service /etc/systemd/system/
   
   # Reload systemd
   systemctl daemon-reload
   ```

### 2. High Availability

1. **Primary Node**
   ```bash
   # Configure as primary
   ./scripts/ha-setup.sh --mode primary
   
   # Start services
   systemctl start ssh-ha
   systemctl start ssh-monitor
   ```

2. **Secondary Node**
   ```bash
   # Configure as secondary
   ./scripts/ha-setup.sh --mode secondary
   
   # Start services
   systemctl start ssh-ha
   systemctl start ssh-monitor
   ```

3. **Load Balancer**
   ```nginx
   # /etc/nginx/conf.d/ssh-dashboard.conf
   upstream ssh_dashboard {
       server primary.example.com:3000;
       server secondary.example.com:3000 backup;
   }
   
   server {
       listen 80;
       server_name dashboard.example.com;
       
       location / {
           proxy_pass http://ssh_dashboard;
       }
   }
   ```

### 3. Distributed

1. **Service Discovery**
   ```yaml
   # config/discovery/consul.yaml
   consul:
     host: "localhost"
     port: 8500
     services:
       - name: "ssh-ha"
         port: 22
         tags: ["primary", "ha"]
       - name: "ssh-monitor"
         port: 3000
         tags: ["monitor", "web"]
   ```

2. **Component Distribution**
   ```yaml
   # config/deployment/distributed.yaml
   components:
     ha:
       nodes:
         - host: "ha1.example.com"
           role: "primary"
         - host: "ha2.example.com"
           role: "secondary"
     monitoring:
       nodes:
         - host: "mon1.example.com"
         - host: "mon2.example.com"
     dashboard:
       nodes:
         - host: "web1.example.com"
         - host: "web2.example.com"
   ```

## Security Hardening

### 1. Firewall Configuration

```bash
# Allow SSH
ufw allow 22/tcp

# Allow Dashboard
ufw allow 3000/tcp

# Allow HA sync
ufw allow from <ha-node-ip> to any port 873
```

### 2. SSL/TLS Setup

```nginx
# /etc/nginx/conf.d/ssh-dashboard-ssl.conf
server {
    listen 443 ssl;
    server_name dashboard.example.com;
    
    ssl_certificate /etc/ssl/certs/dashboard.crt;
    ssl_certificate_key /etc/ssl/private/dashboard.key;
    
    location / {
        proxy_pass http://localhost:3000;
    }
}
```

## Monitoring Setup

### 1. System Monitoring

```yaml
# config/monitoring/prometheus.yaml
scrape_configs:
  - job_name: 'ssh-dashboard'
    static_configs:
      - targets: ['localhost:3000']
```

### 2. Log Management

```yaml
# config/monitoring/filebeat.yaml
filebeat.inputs:
- type: log
  paths:
    - /var/log/ssh_dashboard/*.log
```

## Backup Strategy

### 1. Configuration Backup

```yaml
# config/backup/backup.yaml
backup:
  schedule: "0 0 * * *"
  retention: 7
  locations:
    - path: "/backup/config"
      type: "local"
    - path: "s3://backup/config"
      type: "s3"
```

### 2. Data Backup

```yaml
# config/backup/data-backup.yaml
backup:
  schedule: "0 */6 * * *"
  retention: 30
  locations:
    - path: "/backup/data"
      type: "local"
    - path: "s3://backup/data"
      type: "s3"
```

## Best Practices

1. **Security**
   - Regular updates
   - Security hardening
   - Access control
   - Audit logging

2. **Performance**
   - Load balancing
   - Caching
   - Resource monitoring
   - Optimization

3. **Maintenance**
   - Regular backups
   - Health checks
   - Documentation
   - Disaster recovery

## Related Documentation

- [Installation Guide](installation.md)
- [Configuration Guide](configuration.md)
- [High Availability Guide](high_availability.md)
- [Security Guide](security_configuration.md)

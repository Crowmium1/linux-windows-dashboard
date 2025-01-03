# Metrics Guide

This guide explains how to collect, store, and analyze metrics in the SSH Dashboard Monitor.

## Metric Types

### System Metrics
- CPU usage
- Memory usage
- Disk usage
- Network I/O

### Service Metrics
- Service status
- Response time
- Error rate
- Request count

### Security Metrics
- Authentication attempts
- Failed logins
- Key usage
- Access patterns

## Collection

### System Collection
```yaml
metrics:
  system:
    enabled: true
    interval: 60
    collectors:
      - cpu
      - memory
      - disk
      - network
```

### Service Collection
```yaml
metrics:
  services:
    enabled: true
    interval: 30
    collectors:
      - status
      - response_time
      - errors
      - requests
```

### Custom Collection
```yaml
metrics:
  custom:
    enabled: true
    interval: 60
    collectors:
      - name: "ssh_connections"
        command: "who | wc -l"
        type: "gauge"
```

## Storage

### Time Series Database
```yaml
storage:
  type: "influxdb"
  retention: "30d"
  influxdb:
    url: "http://localhost:8086"
    database: "ssh_dashboard"
    username: "admin"
    password: "password"
```

### Data Format
```json
{
  "measurement": "cpu_usage",
  "tags": {
    "host": "server1",
    "service": "ssh"
  },
  "fields": {
    "value": 45.2
  },
  "timestamp": "2025-01-03T08:42:33Z"
}
```

## Analysis

### Basic Analysis
```sql
-- Average CPU usage last hour
SELECT mean("value")
FROM "cpu_usage"
WHERE time > now() - 1h
GROUP BY time(5m)

-- Peak memory usage by service
SELECT max("value")
FROM "memory_usage"
WHERE time > now() - 24h
GROUP BY "service"
```

### Trend Analysis
```sql
-- Weekly trends
SELECT mean("value")
FROM "service_requests"
WHERE time > now() - 7d
GROUP BY time(1h), "service"

-- Compare periods
SELECT mean("value")
FROM "response_time"
WHERE time > now() - 14d
GROUP BY time(1d), "service"
```

## Visualization

### Grafana Dashboard
```yaml
dashboards:
  system:
    title: "System Metrics"
    refresh: "30s"
    panels:
      - title: "CPU Usage"
        type: "graph"
        metric: "cpu_usage"
      - title: "Memory Usage"
        type: "graph"
        metric: "memory_usage"
```

### Chart Configuration
```yaml
charts:
  cpu:
    type: "line"
    stack: false
    fill: 1
    legend: true
    thresholds:
      - value: 80
        color: "yellow"
      - value: 90
        color: "red"
```

## Alerting

### Alert Rules
```yaml
alerts:
  rules:
    - name: "high_cpu"
      metric: "cpu_usage"
      condition: "> 90"
      duration: "5m"
      severity: "critical"
    
    - name: "service_latency"
      metric: "response_time"
      condition: "> 1000"
      duration: "10m"
      severity: "warning"
```

### Alert Channels
```yaml
channels:
  email:
    enabled: true
    recipients:
      - "admin@example.com"
  
  slack:
    enabled: true
    webhook: "https://hooks.slack.com/services/xxx/yyy/zzz"
    channel: "#alerts"
```

## Retention

### Policies
```yaml
retention:
  policies:
    - name: "raw"
      duration: "7d"
      replication: 1
    - name: "aggregated"
      duration: "30d"
      replication: 1
```

### Aggregation
```yaml
aggregation:
  rules:
    - name: "hourly"
      source: "raw"
      target: "aggregated"
      interval: "1h"
      functions:
        - "mean"
        - "max"
```

## Export

### Data Export
```bash
# Export metrics
ssh-dashboard-ctl metrics export \
  --metric cpu_usage \
  --start "2025-01-01" \
  --end "2025-01-03" \
  --format csv

# Import metrics
ssh-dashboard-ctl metrics import \
  --file metrics.csv \
  --format csv
```

### Report Generation
```yaml
reports:
  daily:
    metrics:
      - cpu_usage
      - memory_usage
      - service_status
    format: "pdf"
    schedule: "0 0 * * *"
```

## Integration

### Prometheus Integration
```yaml
prometheus:
  enabled: true
  port: 9100
  metrics_path: "/metrics"
  scrape_interval: "30s"
```

### StatsD Integration
```yaml
statsd:
  enabled: true
  host: "localhost"
  port: 8125
  prefix: "ssh_dashboard"
```

## Best Practices

1. **Collection**
   - Appropriate intervals
   - Relevant metrics
   - Resource impact
   - Data validation

2. **Storage**
   - Retention policies
   - Backup strategy
   - Performance tuning
   - Capacity planning

3. **Analysis**
   - Regular review
   - Trend analysis
   - Correlation
   - Anomaly detection

## Related Documentation

- [Monitoring Guide](monitoring.md)
- [Alerting Guide](alerting.md)
- [Dashboard Guide](../Dashboard/overview.md)
- [Integration Guide](../Integration/api_integration.md)

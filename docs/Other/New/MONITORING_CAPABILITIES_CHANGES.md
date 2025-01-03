# Monitoring Capabilities Changes Required

## 1. Real-time Monitoring

### Current State
```bash
# Basic interval-based checks
# No real-time updates
# Manual data collection
```

### Required Changes
```bash
# Add to lib/real_time_monitor.sh
#!/bin/bash

MONITOR_SOCKET="/var/run/monitor/monitor.sock"
METRICS_DIR="/var/lib/monitor/metrics"
UPDATE_INTERVAL=1  # seconds

initialize_monitor() {
    mkdir -p "$(dirname "$MONITOR_SOCKET")" "$METRICS_DIR"
    
    # Create monitoring socket
    if [ -e "$MONITOR_SOCKET" ]; then
        rm "$MONITOR_SOCKET"
    fi
    socat UNIX-LISTEN:$MONITOR_SOCKET,fork,mode=600 EXEC:./handle_metric.sh &
}

collect_metrics() {
    while true; do
        # CPU metrics
        collect_cpu_metrics
        
        # Memory metrics
        collect_memory_metrics
        
        # Disk metrics
        collect_disk_metrics
        
        # Network metrics
        collect_network_metrics
        
        sleep "$UPDATE_INTERVAL"
    done
}

collect_cpu_metrics() {
    local timestamp=$(date +%s)
    local cpu_data
    
    # Collect detailed CPU stats
    cpu_data=$(cat /proc/stat | grep '^cpu')
    
    # Parse and store metrics
    while read -r line; do
        local cpu_name=$(echo "$line" | awk '{print $1}')
        local user=$(echo "$line" | awk '{print $2}')
        local nice=$(echo "$line" | awk '{print $3}')
        local system=$(echo "$line" | awk '{print $4}')
        local idle=$(echo "$line" | awk '{print $5}')
        
        echo "{
            \"timestamp\": $timestamp,
            \"cpu\": \"$cpu_name\",
            \"user\": $user,
            \"nice\": $nice,
            \"system\": $system,
            \"idle\": $idle
        }" > "$METRICS_DIR/cpu_${cpu_name}_${timestamp}.json"
    done <<< "$cpu_data"
}

collect_memory_metrics() {
    local timestamp=$(date +%s)
    local mem_data=$(cat /proc/meminfo)
    
    echo "{
        \"timestamp\": $timestamp,
        \"total\": $(echo "$mem_data" | grep MemTotal | awk '{print $2}'),
        \"free\": $(echo "$mem_data" | grep MemFree | awk '{print $2}'),
        \"available\": $(echo "$mem_data" | grep MemAvailable | awk '{print $2}'),
        \"buffers\": $(echo "$mem_data" | grep Buffers | awk '{print $2}'),
        \"cached\": $(echo "$mem_data" | grep ^Cached | awk '{print $2}')
    }" > "$METRICS_DIR/memory_${timestamp}.json"
}
```

## 2. Performance Metrics

### Current State
```bash
# Basic system info collection
# No performance tracking
# Limited metric storage
```

### Required Changes
```bash
# Add to lib/performance_metrics.sh
#!/bin/bash

METRICS_DB="/var/lib/monitor/metrics.db"
RETENTION_DAYS=30

initialize_metrics_db() {
    sqlite3 "$METRICS_DB" << EOF
CREATE TABLE IF NOT EXISTS metrics (
    id INTEGER PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    metric_type TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value REAL NOT NULL,
    tags TEXT
);

CREATE INDEX IF NOT EXISTS idx_metrics_timestamp 
ON metrics(timestamp);

CREATE INDEX IF NOT EXISTS idx_metrics_type_name 
ON metrics(metric_type, metric_name);
EOF
}

store_metric() {
    local metric_type="$1"
    local metric_name="$2"
    local value="$3"
    local tags="${4:-}"
    local timestamp=$(date +%s)
    
    sqlite3 "$METRICS_DB" << EOF
INSERT INTO metrics (timestamp, metric_type, metric_name, value, tags)
VALUES ($timestamp, '$metric_type', '$metric_name', $value, '$tags');
EOF
}

query_metrics() {
    local metric_type="$1"
    local metric_name="$2"
    local start_time="$3"
    local end_time="${4:-$(date +%s)}"
    
    sqlite3 -json "$METRICS_DB" << EOF
SELECT timestamp, value, tags
FROM metrics
WHERE metric_type = '$metric_type'
AND metric_name = '$metric_name'
AND timestamp BETWEEN $start_time AND $end_time
ORDER BY timestamp;
EOF
}

cleanup_old_metrics() {
    local cutoff=$(($(date +%s) - $RETENTION_DAYS * 86400))
    
    sqlite3 "$METRICS_DB" << EOF
DELETE FROM metrics
WHERE timestamp < $cutoff;

VACUUM;
EOF
}
```

## 3. Resource Tracking

### Current State
```bash
# Basic resource checks
# No trend analysis
# No threshold alerts
```

### Required Changes
```bash
# Add to lib/resource_tracker.sh
#!/bin/bash

RESOURCE_CONFIG="/etc/monitor/resources.yaml"
ALERT_THRESHOLD=80  # percent

initialize_resource_tracker() {
    if [ ! -f "$RESOURCE_CONFIG" ]; then
        echo "resources:
  cpu:
    warning_threshold: 80
    critical_threshold: 90
    check_interval: 60
  memory:
    warning_threshold: 80
    critical_threshold: 90
    check_interval: 60
  disk:
    warning_threshold: 80
    critical_threshold: 90
    check_interval: 300
  network:
    warning_threshold: 70
    critical_threshold: 85
    check_interval: 60" > "$RESOURCE_CONFIG"
    fi
}

track_resources() {
    while true; do
        # Track CPU usage
        track_cpu_usage
        
        # Track memory usage
        track_memory_usage
        
        # Track disk usage
        track_disk_usage
        
        # Track network usage
        track_network_usage
        
        sleep $(yq -r '.resources.cpu.check_interval' "$RESOURCE_CONFIG")
    done
}

track_cpu_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    local warning_threshold=$(yq -r '.resources.cpu.warning_threshold' "$RESOURCE_CONFIG")
    local critical_threshold=$(yq -r '.resources.cpu.critical_threshold' "$RESOURCE_CONFIG")
    
    store_metric "cpu" "usage" "$cpu_usage" "source=top"
    
    if (( $(echo "$cpu_usage > $critical_threshold" | bc -l) )); then
        trigger_alert "cpu" "CRITICAL" "$cpu_usage"
    elif (( $(echo "$cpu_usage > $warning_threshold" | bc -l) )); then
        trigger_alert "cpu" "WARNING" "$cpu_usage"
    fi
}
```

## 4. Alert System

### Current State
```bash
# Basic error logging
# No alert management
# No notification system
```

### Required Changes
```bash
# Add to lib/alert_manager.sh
#!/bin/bash

ALERT_CONFIG="/etc/monitor/alerts.yaml"
ALERT_DB="/var/lib/monitor/alerts.db"
NOTIFICATION_SOCKET="/var/run/monitor/notifications.sock"

initialize_alert_manager() {
    # Create alert database
    sqlite3 "$ALERT_DB" << EOF
CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    severity TEXT NOT NULL,
    source TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL,
    resolved_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_alerts_status 
ON alerts(status);
EOF

    # Create notification socket
    if [ -e "$NOTIFICATION_SOCKET" ]; then
        rm "$NOTIFICATION_SOCKET"
    fi
    socat UNIX-LISTEN:$NOTIFICATION_SOCKET,fork,mode=600 EXEC:./handle_notification.sh &
}

trigger_alert() {
    local source="$1"
    local severity="$2"
    local message="$3"
    local timestamp=$(date +%s)
    
    # Store alert
    sqlite3 "$ALERT_DB" << EOF
INSERT INTO alerts (timestamp, severity, source, message, status)
VALUES ($timestamp, '$severity', '$source', '$message', 'active');
EOF

    # Send notifications
    send_notifications "$severity" "$message"
}

send_notifications() {
    local severity="$1"
    local message="$2"
    
    # Load notification config
    local notify_email=$(yq -r '.notifications.email.enabled' "$ALERT_CONFIG")
    local notify_slack=$(yq -r '.notifications.slack.enabled' "$ALERT_CONFIG")
    
    if [ "$notify_email" = "true" ]; then
        send_email_alert "$severity" "$message"
    fi
    
    if [ "$notify_slack" = "true" ]; then
        send_slack_alert "$severity" "$message"
    fi
}

send_email_alert() {
    local severity="$1"
    local message="$2"
    local recipients=$(yq -r '.notifications.email.recipients[]' "$ALERT_CONFIG")
    
    for recipient in $recipients; do
        echo "Subject: [$severity] Monitor Alert
        
        $message" | sendmail -t "$recipient"
    done
}

send_slack_alert() {
    local severity="$1"
    local message="$2"
    local webhook_url=$(yq -r '.notifications.slack.webhook_url' "$ALERT_CONFIG")
    
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"[$severity] $message\"}" \
        "$webhook_url"
}

resolve_alert() {
    local alert_id="$1"
    local timestamp=$(date +%s)
    
    sqlite3 "$ALERT_DB" << EOF
UPDATE alerts
SET status = 'resolved',
    resolved_at = $timestamp
WHERE id = $alert_id;
EOF
}
```

## Implementation Strategy

1. Phase 1: Real-time Monitoring
   - Set up metric collection
   - Implement data storage
   - Create update mechanism

2. Phase 2: Performance Tracking
   - Create metrics database
   - Add collection routines
   - Implement cleanup

3. Phase 3: Resource Management
   - Add resource tracking
   - Implement thresholds
   - Create trend analysis

4. Phase 4: Alerting
   - Set up alert system
   - Add notification channels
   - Create alert management

## Testing Requirements

1. Monitoring Tests
   - Data collection
   - Storage efficiency
   - Update frequency

2. Performance Tests
   - Metric accuracy
   - Database performance
   - Query optimization

3. Resource Tests
   - Threshold accuracy
   - Trend detection
   - Alert triggering

4. Alert Tests
   - Notification delivery
   - Alert lifecycle
   - Resolution handling

## Security Considerations

1. Data Security
   - Metric encryption
   - Access control
   - Secure storage

2. Communication
   - Socket security
   - Notification security
   - Channel encryption

3. Resource Usage
   - Monitor impact
   - Storage limits
   - Cleanup procedures

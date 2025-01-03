#!/bin/bash

# Metrics collection for SSH Dashboard Monitor
# Collects and stores various metrics about SSH connections and system state

# Source common utilities and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/config/config_loader.sh"
source "${SCRIPT_DIR}/../../utils/utils.sh"

# Load metrics configuration
METRICS_CONFIG="${SCRIPT_DIR}/../../config/monitoring/metrics.yaml"

# Global variables
declare -A METRICS_CACHE
LAST_EXPORT_TIME=0

# Function to load metrics configuration
load_metrics_config() {
    if [[ ! -f "${METRICS_CONFIG}" ]]; then
        log_error "Metrics configuration not found: ${METRICS_CONFIG}"
        return 1
    fi
    
    # Load using parse_yaml from config_loader.sh
    eval "$(parse_yaml "${METRICS_CONFIG}")"
}

# Function to collect connection metrics
collect_connection_metrics() {
    local host=$1
    local metrics=()
    
    # Measure latency
    local latency
    latency=$(ping -c 1 "${host}" | grep -oP 'time=\K[0-9.]+' || echo "0")
    metrics+=("latency=${latency}")
    
    # Check packet loss
    local packet_loss
    packet_loss=$(ping -c 5 "${host}" | grep -oP '[0-9.]+(?=% packet loss)' || echo "100")
    metrics+=("packet_loss=${packet_loss}")
    
    # Get active connections
    local active_connections
    active_connections=$(ss -tn | grep -c "${host}")
    metrics+=("active_connections=${active_connections}")
    
    # Measure bandwidth (if iperf3 is available)
    if command -v iperf3 >/dev/null; then
        local bandwidth
        bandwidth=$(iperf3 -c "${host}" -t 1 -J | jq '.end.sum_received.bits_per_second/1000000' || echo "0")
        metrics+=("bandwidth=${bandwidth}")
    fi
    
    echo "${metrics[*]}"
}

# Function to collect system metrics
collect_system_metrics() {
    local metrics=()
    
    # CPU usage
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    metrics+=("cpu_usage=${cpu_usage}")
    
    # Memory usage
    local memory_usage
    memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100}')
    metrics+=("memory_usage=${memory_usage}")
    
    # Disk usage
    local disk_usage
    disk_usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    metrics+=("disk_usage=${disk_usage}")
    
    # Network I/O
    local network_rx network_tx
    read -r network_rx network_tx < <(awk '{if($1=="eth0:"){print $2, $10}}' /proc/net/dev)
    metrics+=("network_rx=${network_rx}" "network_tx=${network_tx}")
    
    echo "${metrics[*]}"
}

# Function to collect service metrics
collect_service_metrics() {
    local service=$1
    local metrics=()
    
    # Service status
    local status
    status=$(systemctl is-active "${service}")
    metrics+=("status=${status}")
    
    # Uptime
    local uptime
    uptime=$(systemctl show "${service}" -p ActiveEnterTimestamp | cut -d= -f2)
    metrics+=("uptime=${uptime}")
    
    # Restart count
    local restart_count
    restart_count=$(systemctl show "${service}" -p NRestarts | cut -d= -f2)
    metrics+=("restart_count=${restart_count}")
    
    echo "${metrics[*]}"
}

# Function to store metrics
store_metrics() {
    local metric_type=$1
    local timestamp=$2
    shift 2
    local metrics=("$@")
    
    case "${storage_type}" in
        "file")
            store_metrics_file "${metric_type}" "${timestamp}" "${metrics[@]}"
            ;;
        "sqlite")
            store_metrics_sqlite "${metric_type}" "${timestamp}" "${metrics[@]}"
            ;;
        "prometheus")
            store_metrics_prometheus "${metric_type}" "${timestamp}" "${metrics[@]}"
            ;;
    esac
}

# Function to store metrics in file
store_metrics_file() {
    local metric_type=$1
    local timestamp=$2
    shift 2
    local metrics=("$@")
    
    local storage_path="${storage_file_path}/${metric_type}"
    mkdir -p "${storage_path}"
    
    local file="${storage_path}/$(date '+%Y%m%d').${storage_file_format}"
    
    case "${storage_file_format}" in
        "csv")
            echo "${timestamp},${metrics[*]}" >> "${file}"
            ;;
        "json")
            local json="{\"timestamp\":\"${timestamp}\",\"metrics\":{${metrics[*]}}}"
            echo "${json}" >> "${file}"
            ;;
    esac
    
    # Rotate files if needed
    rotate_metric_files "${storage_path}"
}

# Function to rotate metric files
rotate_metric_files() {
    local storage_path=$1
    local max_size=$((storage_file_max_size_mb * 1024 * 1024))
    
    find "${storage_path}" -type f -name "*.${storage_file_format}" | while read -r file; do
        if [[ -f "${file}" ]] && [[ $(stat -f%z "${file}") -gt ${max_size} ]]; then
            mv "${file}" "${file}.1"
            touch "${file}"
        fi
    done
    
    # Clean up old rotated files
    find "${storage_path}" -type f -name "*.${storage_file_format}.*" | sort -r | \
        tail -n "+$((storage_file_rotate_count + 1))" | xargs rm -f
}

# Function to export metrics
export_metrics() {
    local current_time
    current_time=$(date +%s)
    
    # Check if it's time to export
    if [[ $((current_time - LAST_EXPORT_TIME)) -lt $((export_schedule_interval_hours * 3600)) ]]; then
        return 0
    fi
    
    local export_path="${export_destination_path}/$(date '+%Y%m%d_%H%M%S')"
    mkdir -p "${export_path}"
    
    # Export for each format
    for format in "${export_formats[@]}"; do
        case "${format}" in
            "json")
                export_metrics_json "${export_path}"
                ;;
            "csv")
                export_metrics_csv "${export_path}"
                ;;
            "prometheus")
                export_metrics_prometheus "${export_path}"
                ;;
        esac
    done
    
    LAST_EXPORT_TIME=${current_time}
    
    # Cleanup old exports
    find "$(dirname "${export_path}")" -maxdepth 1 -type d -mtime "+${export_schedule_retention_count}" -exec rm -rf {} \;
}

# Main function
main() {
    # Load configuration
    if ! load_metrics_config; then
        exit 1
    fi
    
    # Process command line arguments
    case "$1" in
        collect)
            case "$2" in
                connection)
                    metrics=($(collect_connection_metrics "$3"))
                    store_metrics "connection" "$(date -Iseconds)" "${metrics[@]}"
                    ;;
                system)
                    metrics=($(collect_system_metrics))
                    store_metrics "system" "$(date -Iseconds)" "${metrics[@]}"
                    ;;
                service)
                    metrics=($(collect_service_metrics "$3"))
                    store_metrics "service" "$(date -Iseconds)" "${metrics[@]}"
                    ;;
                *)
                    echo "Usage: $0 collect {connection <host>|system|service <name>}"
                    exit 1
                    ;;
            esac
            ;;
        export)
            export_metrics
            ;;
        *)
            echo "Usage: $0 {collect {connection <host>|system|service <name>}|export}"
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
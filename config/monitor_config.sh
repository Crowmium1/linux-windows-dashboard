# Monitoring Configuration File (source this file in your bashrc or other env files)

# System Monitoring Configs
export MONITOR_INTERVAL=60
export CPU_THRESHOLD=90
export MEMORY_THRESHOLD=85
export DISK_THRESHOLD=85
export TEMP_THRESHOLD=80
export PING_INTERVAL=30
export NETWORK_RETRY_COUNT=3

# Backup Configuration
export BACKUP_ENABLED=true
export BACKUP_INTERVAL=86400
export BACKUP_RETENTION=5
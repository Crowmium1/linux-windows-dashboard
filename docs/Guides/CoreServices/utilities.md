# SSH Dashboard Utilities Guide

This guide explains the utility functions available in the SSH Dashboard Monitor project.

## Overview

The utilities provide common functionality for:
- File and directory management
- Logging and notifications
- Security checks
- Process management
- Configuration parsing
- System compatibility

## Core Utilities

### Environment Detection

```bash
# Check if running in test mode
is_test_mode

# Check if running in Windows Subsystem for Linux
is_wsl
```

### Command Management

```bash
# Check if a command exists
check_command "command_name"

# Run command with timeout
run_with_timeout "command" # 5 second timeout
```

### File System Operations

```bash
# Check directory permissions
check_directory_permissions "/path/to/dir"

# Check available disk space
check_disk_space # Requires 10MB minimum

# Sanitize and validate paths
sanitize_path "/user/input/path"
validate_path "/path/to/check"

# Create archive of directory
create_archive "/source/dir" "archive_name.tar.gz"

# Clean old files
cleanup_old_files "/path/to/dir" 7 # Remove files older than 7 days
```

### Logging System

```bash
# Log messages with different levels
log_info "Operation completed successfully"
log_warning "Resource usage high"
log_error "Operation failed"

# Custom log file
log_info "Custom message" "/path/to/custom.log"
```

### Notification System

```bash
# Send notifications
send_notification "email" "Alert message"
send_notification "slack" "Status update"
```

### Security Operations

```bash
# Validate SSH key permissions
validate_ssh_key "~/.ssh/id_rsa" 600

# Check port availability
check_port "hostname" 22 5 # 5 second timeout
```

### Process Management

```bash
# Get process status
get_process_status "process_name"
```

### Configuration Management

```bash
# Parse YAML configuration
parse_yaml "config.yaml" "CONFIG_"
```

## Best Practices

### 1. File Operations

- Always use `sanitize_path` for user inputs
- Check permissions with `check_directory_permissions`
- Validate paths with `validate_path`
- Use `cleanup_old_files` for maintenance

### 2. Logging

- Use appropriate log levels
- Include context in messages
- Set reasonable log rotation sizes
- Use custom log files for specific components

### 3. Security

- Always validate SSH key permissions
- Use timeouts for network operations
- Check command existence before use
- Validate all user inputs

### 4. Error Handling

- Check return values
- Log errors appropriately
- Use descriptive error messages
- Implement proper cleanup

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TEST_MODE` | Enable test mode | 0 |
| `LOG_MAX_SIZE` | Maximum log file size | 10MB |
| `HA_LOG_DIR` | Log directory | ~/.ssh_dashboard/logs |
| `NOTIFY_EMAIL` | Notification email | |
| `NOTIFY_SLACK_WEBHOOK` | Slack webhook URL | |

## Directory Structure

```
lib/utils/
└── utils.sh           # Main utilities file

logs/
├── ha.log            # Main log file
├── security.log      # Security-related logs
└── monitoring.log    # Monitoring logs
```

## Common Use Cases

### 1. Safe File Operations

```bash
# Safe directory creation
if check_directory_permissions "/path/to/new/dir"; then
    log_info "Directory created successfully"
else
    log_error "Failed to create directory"
fi
```

### 2. Process Management

```bash
# Check and manage processes
status=$(get_process_status "sshd")
if [ "$status" = "stopped" ]; then
    log_error "SSH service is not running"
    send_notification "slack" "SSH service down"
fi
```

### 3. Configuration Loading

```bash
# Load and use YAML configuration
eval $(parse_yaml "config.yaml" "CONFIG_")
echo "Host: ${CONFIG_ssh_host}"
```

### 4. Security Checks

```bash
# Validate SSH setup
if ! validate_ssh_key "${SSH_KEY_PATH}"; then
    log_error "Invalid SSH key permissions"
    send_notification "email" "Security issue: SSH key permissions"
fi
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   - Check file permissions
   - Verify user permissions
   - Use `check_directory_permissions`

2. **Command Not Found**
   - Use `check_command`
   - Verify PATH settings
   - Check package installation

3. **Log Issues**
   - Check directory permissions
   - Verify log rotation settings
   - Monitor disk space

4. **Network Problems**
   - Use `check_port`
   - Verify timeouts
   - Check network connectivity

## Related Documentation

- [Security Configuration](security_configuration.md)
- [Monitoring Configuration](monitoring_configuration.md)
- [High Availability Guide](high_availability.md)

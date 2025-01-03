# Environment-Specific Configuration Guide

## Overview
The SSH Dashboard Monitor supports multiple environments (Windows, Linux, WSL) through environment-specific configuration files. This guide explains how to use and test the configuration system.

## Directory Structure
```
config/
├── main_config.yaml           # Main configuration file
└── environments/             # Environment-specific configs
    ├── windows.yaml
    ├── linux.yaml
    └── wsl.yaml
```

## Using the Configuration System

### 1. Loading Configuration
Add these lines at the start of your script:

```bash
# Source the config loader
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config/config_loader.sh"

# Load environment-specific config
load_environment_config || {
    echo "Failed to load environment configuration"
    exit 1
}
```

### 2. Using Configuration Values
Use the `get_config` function to safely retrieve configuration values:

```bash
# Get a config value with default
log_dir=$(get_config LOG_DIR "/var/log")
ssh_cmd=$(get_config SSH_CMD "/usr/bin/ssh")

# Use in commands
"${ssh_cmd}" -V
mkdir -p "${log_dir}"
```

### 3. Environment Detection
The system automatically detects the environment:
- WSL: Checks for `WSL_DISTRO_NAME`
- Windows: Checks for `OSTYPE=msys` or `win32`
- Linux: Checks for `OSTYPE=linux-gnu`

## Configuration Files

### Main Config (main_config.yaml)
Contains common settings used across all environments:
```yaml
MONITOR_INTERVAL: 60
CPU_THRESHOLD: 80
SSH_PORT: 22
```

### Environment Config (environments/*.yaml)
Contains environment-specific settings:
```yaml
# System paths
LOG_DIR: '/var/log/ssh_dashboard'
SSH_CMD: '/usr/bin/ssh'

# Environment settings
USE_POWERSHELL: false
PATH_SEPARATOR: '/'
```

## Testing Configuration

### Manual Testing
1. Test environment detection:
```bash
source lib/config/config_loader.sh
detect_environment
```

2. Test config loading:
```bash
load_environment_config
echo $LOG_DIR
```

### Automated Testing
Use the test script in `tests/incomplete/test_config_loader.sh`:
```bash
./tests/incomplete/test_config_loader.sh
```

## Troubleshooting

### Common Issues

1. **Config Not Found**
```
Error: Environment config not found: .../environments/unknown.yaml
```
- Check if the environment config file exists
- Verify file permissions

2. **Missing Required Variables**
```
Error: Required variable LOG_DIR not set in config
```
- Check environment config file
- Verify all required variables are defined

3. **Permission Issues**
```
mkdir: cannot create directory '/var/log/ssh_dashboard'
```
- Check directory permissions
- Run with appropriate privileges

### Debug Mode
Enable debug output:
```bash
export DEBUG=true
source lib/config/config_loader.sh
```

## Best Practices

1. **Always Use get_config**
   - Use `get_config` instead of direct variable access
   - Provides fallback values
   - Safer variable handling

2. **Check Return Values**
   - Always check if `load_environment_config` succeeds
   - Handle configuration errors gracefully

3. **Environment Variables**
   - Don't override environment-specific settings
   - Use `main_config.yaml` for common settings

4. **Testing**
   - Test configuration in all supported environments
   - Verify required directories are created
   - Check file permissions

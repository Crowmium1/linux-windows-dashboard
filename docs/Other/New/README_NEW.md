# SSH Dashboard Monitor

## Overview
A comprehensive SSH monitoring and management system designed to track system state, handle reboots, and manage SSH connections across Windows and Unix environments.

## Quick Start

### Windows Users
```powershell
# Launch the monitor
.\run_monitor.ps1
```

### Unix/WSL Users
```bash
# Make scripts executable
chmod +x *.sh

# Start the monitoring helper
./monitor_helper.sh
```

## Core Components

### 1. Monitor Helper (`monitor_helper.sh`)
- Interactive menu interface
- SSH connection management
- System status overview
- Configuration handling

### 2. System Monitor (`system_monitor.sh`)
- Resource monitoring (CPU, Memory, Disk)
- Service status tracking
- Error detection
- Performance metrics

### 3. Reboot Monitor (`reboot_monitor.sh`)
- Pre-reboot state capture
- Post-reboot verification
- State comparison
- Change detection

### 4. System Info Collector (`collect_system_info.sh`)
- Hardware information
- Software state
- Configuration details
- Performance data

### 5. SSH Toolkit (`prepare_ssh_toolkit.sh`)
- Key management
- Connection setup
- Configuration validation
- Security checks

## Configuration

### SSH Settings
Default configuration:
```ini
SSH_HOST=192.168.1.100
SSH_USER=admin
SSH_PORT=22
KEY_TYPE=ed25519
```

### Monitor Settings
```ini
CHECK_INTERVAL=60
LOG_LEVEL=INFO
METRICS_RETENTION=7
```

## Usage Examples

### 1. Basic Monitoring
```bash
# Start monitoring
./monitor_helper.sh start

# Check status
./monitor_helper.sh status

# Stop monitoring
./monitor_helper.sh stop
```

### 2. Reboot Monitoring
```bash
# Before reboot
./reboot_monitor.sh pre-reboot

# After reboot
./reboot_monitor.sh post-reboot

# Compare states
./reboot_monitor.sh compare
```

### 3. System Information
```bash
# Collect all info
./collect_system_info.sh --all

# Specific components
./collect_system_info.sh --cpu --memory --disk
```

## Security

### SSH Key Management
1. Keys stored in `~/.ssh/`
2. Permissions set to 600
3. Passphrase protection recommended
4. Regular key rotation

### Data Protection
1. Encrypted logs
2. Secure configuration storage
3. Protected state files
4. Access control

## Support

### Common Issues
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

### Updates
1. Check for updates regularly
2. Follow security advisories
3. Update configuration as needed

## License
MIT License

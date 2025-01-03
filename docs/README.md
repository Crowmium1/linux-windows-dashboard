# System Monitoring Tools

This directory contains tools for monitoring system state, especially during reboots and configuration changes.

## Quick Start

```bash
# Make scripts executable
chmod +x *.sh

# Start the monitoring helper
./monitor_helper.sh
```

## Available Tools

### 1. monitor_helper.sh
Interactive tool that provides:
- Menu-driven interface
- SSH connection management
- Quick system status
- Reboot monitoring automation

### 2. system_monitor.sh
Detailed system monitoring:
- GPU status
- Power management
- Thermal status
- Service status
- Kernel parameters
- Firmware status
- Error detection

### 3. reboot_monitor.sh
Compares system state before and after reboot:
- Pre-reboot state recording
- Post-reboot state recording
- State comparison
- Change detection

## SSH Configuration

The tools use these SSH settings:
- Username: lj
- Host: 192.168.17.193
- Port: 22

## Usage Examples

### Monitor System During Reboot
1. Start helper:
   ```bash
   ./monitor_helper.sh
   ```
2. Select option 2 to record pre-reboot state
3. Reboot system
4. After reboot, select option 3 to compare states

### Quick Status Check
1. Start helper:
   ```bash
   ./monitor_helper.sh
   ```
2. Select option 4 for quick status

### Manual Monitoring
```bash
# Direct system monitoring
sudo ./system_monitor.sh

# Pre-reboot recording
sudo ./reboot_monitor.sh pre

# Post-reboot comparison
sudo ./reboot_monitor.sh post
```

## Log Files

All logs are stored in `/var/log/system_monitor/`:
- Pre-reboot state: `pre_reboot.log`
- Post-reboot state: `post_reboot.log`
- Comparison results: `reboot_comparison.log`

## Troubleshooting

1. If SSH connection fails:
   - Check if the system is reachable: `ping 192.168.17.193`
   - Verify SSH service: `systemctl status ssh`
   - Check credentials in monitor_helper.sh

2. If monitoring fails:
   - Check script permissions: `ls -l *.sh`
   - Verify log directory exists: `ls /var/log/system_monitor`
   - Check system logs: `journalctl -xe`

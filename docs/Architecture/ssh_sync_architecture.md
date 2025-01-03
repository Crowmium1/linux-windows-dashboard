# SSH and Sync Architecture

## Overview
This document explains the architecture and concepts behind the SSH and synchronization system used in the dashboard monitoring project. The system is designed to maintain secure connections and file synchronization between a local WSL environment and a remote Linux machine.

## Core Components

### 1. SSH Management (`ssh_manager.sh`)
The SSH manager handles interactive SSH operations and provides a user interface for:
- SSH key setup and deployment
- Connection testing and diagnostics
- Port forwarding configuration
- Manual sync operations

```bash
./ssh_manager.sh setup     # Initial SSH setup
./ssh_manager.sh forward   # Configure port forwarding
./ssh_manager.sh sync      # Manual sync
```

### 2. Sync Service (`sync_service.sh`)
A dedicated service for continuous file synchronization that:
- Maintains its own SSH connections
- Operates independently of the SSH manager
- Handles automatic retries and monitoring
- Manages its own process state

```bash
./sync_service.sh start    # Start sync daemon
./sync_service.sh stop     # Stop sync daemon
./sync_service.sh status   # Check sync status
```

## Key Concepts

### SSH Connection Management
1. **Connection Types**
   - **Interactive**: Used by `ssh_manager.sh` for manual operations
   - **Service**: Maintained by `sync_service.sh` for continuous sync
   - **Port Forwarding**: Dedicated connections for dashboard and metrics ports

2. **Process Isolation**
   - Each connection type runs in its own process
   - Prevents interference between different operations
   - Allows independent recovery from failures

3. **Port Forwarding**
   ```
   Local (WSL) ←→ Remote (Linux)
   :8080 ←→ Dashboard Service
   :9090 ←→ Metrics Service
   ```

### File Synchronization

1. **Sync Modes**
   - **Manual**: One-time sync via `ssh_manager.sh`
   - **Automatic**: Continuous sync via `sync_service.sh`
   - **Selective**: Using exclude patterns from config

2. **Sync Strategy**
   ```
   Local Files → rsync → SSH tunnel → Remote Server
   ↑                                    ↓
   Monitor Changes                    Update Files
   ```

3. **Conflict Resolution**
   - Last write wins
   - Local changes take precedence
   - Configurable via sync settings

## Configuration Management

### 1. Directory Structure
```
ssh_dashboard_monitor/
├── ssh/
│   ├── config/
│   │   ├── dashboard_config.conf  # Main configuration
│   │   └── ssh_config            # SSH-specific settings
│   ├── ssh_manager.sh            # Interactive management
│   └── sync_service.sh           # Background sync service
├── utils/
│   └── keyring_diagnostic.sh     # Keyring utilities
└── docs/
    └── SSH_SYNC_ARCHITECTURE.md  # This document
```

### 2. Configuration Files
- **dashboard_config.conf**: Central configuration for all components
- **ssh_config**: SSH-specific settings like hosts and ports

## Security Considerations

### 1. SSH Keys
- Uses Ed25519 keys for better security
- Keys managed through system keyring
- Automatic key deployment to remote hosts

### 2. Port Forwarding Security
- Only necessary ports are forwarded
- Local-only bindings
- Automatic cleanup of forwarded ports

### 3. Process Security
- Separate processes for different operations
- Proper cleanup on exit
- Permission checks on sensitive operations

## Linux-Specific Features

### 1. Process Management
- Uses Linux process isolation
- Proper signal handling
- System service integration (optional)

### 2. File System
- Linux file permissions
- Inotify for file monitoring
- Path compatibility between WSL and Linux

### 3. Network
- SSH connection pooling
- Keep-alive settings
- Network failure recovery

## Common Operations

### 1. Initial Setup
```bash
# 1. Setup SSH keys and configuration
./ssh_manager.sh setup

# 2. Test connection
./ssh_manager.sh check

# 3. Configure port forwarding
./ssh_manager.sh forward

# 4. Start sync service
./sync_service.sh start
```

### 2. Monitoring and Maintenance
```bash
# Check sync status
./sync_service.sh status

# Run diagnostics
./ssh_manager.sh diagnostics

# Manual sync if needed
./ssh_manager.sh sync
```

## Troubleshooting

### 1. Connection Issues
- Check SSH key permissions
- Verify port forwarding
- Review connection logs

### 2. Sync Problems
- Check file permissions
- Verify exclude patterns
- Review sync logs

### 3. Process Management
- Check running processes
- Review service status
- Check system logs

## Best Practices

1. **SSH Management**
   - Regular key rotation
   - Keep known_hosts updated
   - Monitor failed login attempts

2. **Sync Operations**
   - Regular backup of configuration
   - Monitor sync logs
   - Test sync operations periodically

3. **Maintenance**
   - Regular diagnostic runs
   - Log rotation
   - Configuration backups

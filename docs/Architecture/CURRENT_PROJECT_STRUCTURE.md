# SSH Dashboard Monitor - Current Project Structure

```
ssh_dashboard_monitor/
├── core/                       # Core monitoring functionality
│   ├── collect_info.sh        # System information collection
│   ├── collect_system_info.sh # Detailed system metrics collection
│   ├── monitor_helper.sh      # Helper functions for monitoring
│   ├── orchestrator.sh        # Process orchestration and management
│   ├── reboot_monitor.sh      # System reboot monitoring
│   └── run_monitor.ps1        # Windows PowerShell entry point
│
├── config/                    # Configuration files
│   ├── main_config.conf      # Main configuration settings
│   ├── monitor_config.conf   # Monitoring-specific settings
│   ├── security_config.conf  # Security and access settings
│   ├── ssh_config.conf       # SSH connection settings
│   └── templates/            # Configuration templates
│       └── *.conf.template   # Template files
│
├── lib/                      # Library modules and utilities
│   ├── monitoring/          # Monitoring utilities
│   │   ├── alerts.sh       # Alert management
│   │   ├── metrics.sh      # Metrics collection
│   │   └── status.sh       # Status tracking
│   ├── security/           # Security utilities
│   │   ├── keyring.sh     # SSH key management
│   │   └── session.sh     # Session management
│   └── utils/             # Common utilities
│       ├── cleanup.sh     # Cleanup operations
│       ├── logging.sh     # Logging functions
│       └── utils.sh       # General utility functions
│
├── tests/                   # Test suite
│   ├── complete/           # Completed and passing tests
│   │   ├── test_cleanup.sh
│   │   ├── test_collect_info.sh
│   │   ├── test_collect_system_info.sh
│   │   ├── test_data_collection.sh
│   │   ├── test_error_handling.sh
│   │   ├── test_integration.sh
│   │   ├── test_keyring_diagnostic.sh
│   │   ├── test_monitor_helper.sh
│   │   ├── test_monitoring.sh
│   │   └── test_security.sh
│   ├── incomplete/         # Tests in development
│   │   ├── test_logout.sh
│   │   ├── test_orchestrator.sh
│   │   ├── test_reboot_monitor.sh
│   │   ├── test_run_monitor.ps1
│   │   ├── test_ssh_manager.sh
│   │   └── test_sync_service.sh
│   └── var/               # Test data and temporary files
│       ├── data/         # Test data files
│       │   ├── cleanup/
│       │   ├── collect_info/
│       │   ├── monitoring/
│       │   └── security/
│       ├── log/          # Test log files
│       └── tmp/          # Temporary test files
│
├── var/                    # Runtime data
│   ├── data/              # Application data
│   │   ├── collect_info/  # Collected system information
│   │   ├── monitoring/    # Monitoring data
│   │   └── security/      # Security-related data
│   ├── log/               # Application logs
│   └── tmp/               # Temporary files
│
├── docs/                   # Documentation
│   ├── api/               # API documentation
│   ├── config/            # Configuration guides
│   ├── deployment/        # Deployment guides
│   └── monitoring/        # Monitoring documentation
│
└── archive/               # Archived files and backups
    ├── configs/           # Old configurations
    └── logs/              # Old logs

```

## Key Components

1. **Core Components**
   - System monitoring and data collection
   - Process orchestration
   - Reboot monitoring
   - Windows PowerShell integration

2. **Configuration Management**
   - Main system configuration
   - Monitor-specific settings
   - Security settings
   - SSH connection settings
   - Configuration templates

3. **Library Modules**
   - Monitoring utilities
   - Security utilities
   - Common utilities
   - Logging and cleanup

4. **Test Suite**
   - Complete (passing) tests
   - Incomplete (in development) tests
   - Test data and temporary files
   - Test logs

5. **Runtime Data**
   - Application data storage
   - Log files
   - Temporary files
   - Data collection results

6. **Documentation**
   - API documentation
   - Configuration guides
   - Deployment guides
   - Monitoring documentation

7. **Archive**
   - Old configurations
   - Historical logs
   - Backup data

## File Permissions

1. **Directories**
   - Standard directories: 755 (rwxr-xr-x)
   - Security-sensitive dirs: 700 (rwx------)
   - Log directories: 755 (rwxr-xr-x)

2. **Files**
   - Shell scripts (.sh): 755 (rwxr-xr-x)
   - PowerShell scripts (.ps1): 755 (rwxr-xr-x)
   - Config files (.conf): 644 (rw-r--r--)
   - Templates: 644 (rw-r--r--)
   - Log files: 644 (rw-r--r--)
   - SSH keys: 600 (rw-------)

## Environment Variables

```bash
# Base Directories
ROOT_DIR          # Project root directory
CONFIG_DIR        # Configuration directory
LIB_DIR           # Library directory
VAR_DIR           # Variable data directory
LOG_DIR           # Log directory
TEMP_DIR          # Temporary directory

# Test Environment
TEST_MODE         # Test mode flag
TEST_BASE_DIR     # Test base directory
TEST_CONFIG_DIR   # Test configuration directory
TEST_LOG_DIR      # Test log directory
TEST_DATA_DIR     # Test data directory
TEST_TEMP_DIR     # Test temporary directory

# Monitoring Settings
MONITOR_INTERVAL  # Monitoring interval
CPU_THRESHOLD     # CPU usage threshold
MEMORY_THRESHOLD  # Memory usage threshold
DISK_THRESHOLD    # Disk usage threshold
TEMP_THRESHOLD    # Temperature threshold

# SSH Settings
SSH_USER          # SSH username
SSH_HOST          # SSH host
SSH_PORT          # SSH port
SSH_KEY_TYPE      # SSH key type
SSH_KEY_BITS      # SSH key bits

# Security Settings
MAX_RETRIES       # Maximum retry attempts
RETRY_DELAY       # Delay between retries
SESSION_TIMEOUT   # Session timeout period
```

## Dependencies

1. **System Requirements**
   - Bash shell (4.0+)
   - PowerShell (5.1+ for Windows)
   - SSH client
   - System monitoring tools

2. **External Tools**
   - sshd (OpenSSH server)
   - ssh-keygen
   - ssh-agent
   - systemctl/service

3. **Optional Tools**
   - stress-ng (for testing)
   - netstat
   - tcpdump

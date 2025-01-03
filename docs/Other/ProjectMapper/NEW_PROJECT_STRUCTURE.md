# SSH Dashboard Monitor Project Structure

```
ssh_dashboard_monitor/
├── core/                      # Core functionality
│   ├── monitor_helper.sh      # Main interactive interface
│   ├── system_monitor.sh      # System monitoring functions
│   ├── reboot_monitor.sh      # Reboot state management
│   ├── collect_system_info.sh # System information collection
│   └── run_monitor.ps1        # Windows entry point
│
├── lib/                       # Shared libraries and utilities
│   ├── config/               # Configuration management
│   │   ├── config_loader.sh
│   │   └── validator.sh
│   ├── security/            # Security-related utilities
│   │   ├── key_manager.sh
│   │   ├── session_manager.sh
│   │   └── encryption.sh
│   ├── monitoring/          # Monitoring utilities
│   │   ├── metrics.sh
│   │   ├── alerts.sh
│   │   └── resource_tracker.sh
│   └── utils/              # General utilities
│       ├── logger.sh
│       ├── error_handler.sh
│       └── path_manager.sh
│
├── ssh/                     # SSH-related functionality
│   ├── ssh_manager.sh      # SSH connection management
│   ├── sync_service.sh     # File synchronization
│   └── setup_environment.sh # Environment setup
│
├── config/                 # Configuration files
│   ├── default/           # Default configurations
│   │   ├── monitor.yaml
│   │   ├── ssh.yaml
│   │   └── alerts.yaml
│   ├── environments/      # Environment-specific configs
│   │   ├── windows.yaml
│   │   ├── linux.yaml
│   │   └── wsl.yaml
│   └── templates/         # Configuration templates
│       └── config.yaml.template
│
├── tests/                  # Test suite
│   ├── unit/              # Unit tests
│   │   ├── test_system_monitor.sh
│   │   ├── test_reboot_monitor.sh
│   │   └── test_ssh_manager.sh
│   ├── integration/       # Integration tests
│   │   ├── test_monitoring.sh
│   │   └── test_sync.sh
│   ├── data/             # Test data
│   │   └── mock_data/
│   ├── utils/            # Test utilities
│   │   ├── test_helpers.sh
│   │   └── assertions.sh
│   └── run_tests.sh      # Test runner
│
├── docs/                  # Documentation
│   ├── Architecture/     # Architecture documentation
│   │   └── SERVICE_ARCHITECTURE.md
│   ├── New/             # New system documentation
│   │   ├── README_NEW.md
│   │   └── SERVICE_ARCHITECTURE_NEW.md
│   ├── Tests/           # Test documentation
│   │   └── TEST_FAILURE_REPORT.md
│   ├── Configuration/   # Configuration guides
│   │   └── CONFIGURATION_EXAMPLES.md
│   └── Troubleshooting/ # Troubleshooting guides
│       └── TROUBLESHOOTING.md
│
├── scripts/              # Utility scripts
│   ├── install.sh       # Installation script
│   ├── setup.sh         # Setup script
│   └── cleanup.sh       # Cleanup script
│
├── logs/                # Log files
│   ├── monitor/        # Monitor logs
│   ├── ssh/           # SSH logs
│   └── error/         # Error logs
│
├── var/                # Variable data
│   ├── run/           # Runtime data
│   │   └── pid/       # PID files
│   ├── lib/           # Library data
│   │   └── metrics/   # Metrics storage
│   └── cache/         # Cache data
│
├── .gitignore         # Git ignore file
├── README.md          # Project README
├── CHANGELOG.md       # Change log
└── LICENSE           # License file
```

## Key Features of This Structure

1. **Separation of Concerns**
   - Core functionality isolated in `core/`
   - Shared libraries in `lib/`
   - SSH-specific code in `ssh/`

2. **Configuration Management**
   - Default configs in `config/default/`
   - Environment-specific configs in `config/environments/`
   - Templates in `config/templates/`

3. **Testing Organization**
   - Separate unit and integration tests
   - Test utilities and helpers
   - Mock data management

4. **Documentation Structure**
   - Architecture documentation
   - Configuration guides
   - Test documentation
   - Troubleshooting guides

5. **Runtime Data Management**
   - Clear separation of logs
   - Runtime data in `var/run/`
   - Metrics storage in `var/lib/`
   - Cache in `var/cache/`

6. **Security Considerations**
   - Separate security utilities
   - Isolated SSH management
   - Protected configuration storage

## Implementation Notes

1. **File Permissions**
   - Configuration files: 600
   - Executable scripts: 755
   - Log directories: 755
   - PID directory: 755

2. **Environment Variables**
   - `MONITOR_ROOT`: Project root directory
   - `MONITOR_CONFIG`: Configuration directory
   - `MONITOR_LOG`: Log directory
   - `MONITOR_VAR`: Variable data directory

3. **Path Resolution**
   - All scripts should use absolute paths
   - Path resolution through `lib/utils/path_manager.sh`
   - Environment-aware path handling

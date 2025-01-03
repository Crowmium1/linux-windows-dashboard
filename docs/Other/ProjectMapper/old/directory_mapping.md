## Directory Purpose Map

### 1. Core Directories
core/               # Core System Functionality
├── collect_system_info.sh
├── monitor_helper.sh
├── orchestrator.sh
├── reboot_monitor.sh
├── run_monitor.ps1
└── system_monitor.sh
Purpose: Main system operations
Owner: System administrator
Access: Root/admin only

ssh/                # SSH Operations
├── logout.sh
├── setup_environment.sh
├── setup_passwordless_ssh.sh
├── ssh_control.sh
├── ssh_manager.sh
├── ssh_recovery_tools.sh
└── sync_helper.sh
Purpose: SSH connection management
Owner: SSH service
Access: SSH users

utils/              # Utility Functions
├── cleanup.sh
├── keyring_diagnostic.sh
└── utils.sh
Purpose: Common functions
Owner: System
Access: All scripts

### 2. Data Directories
config/             # Configuration
├── Purpose: System configuration
├── Retention: Permanent
└── Backup: Required

log/                # Logging
├── Purpose: System logs
├── Retention: Rotated
└── Cleanup: Automated

tmp/                # Temporary Files
├── Purpose: Runtime data
├── Retention: Session only
└── Cleanup: On exit

### 3. Library Directories
lib/                # Library Functions
├── monitoring/     # System monitoring
│   ├── Purpose: System metrics and alerts
│   └── Access: Core monitoring scripts
├── security/      # Security functions
│   ├── Purpose: Encryption and sessions
│   └── Access: SSH scripts
└── utils/         # Common utilities
    ├── Purpose: Error handling and logging
    └── Access: All scripts

### 4. Test Directories
tests/
├── done/          # Completed Tests
│   ├── Purpose: Verified tests
│   └── Status: Production ready
├── fixtures/      # Test Data
│   ├── Purpose: Test inputs
│   └── Status: Read-only
└── utils/         # Test Utilities
    ├── Purpose: Test support
    └── Status: Development only

## Directory Access Patterns

### 1. Runtime Access
Production:
├── read: config/, utils/
├── write: log/, tmp/
└── execute: core/, ssh/

Testing:
├── read: tests/fixtures/
├── write: tests/*/tmp/
└── execute: tests/done/

## Directory Migration Plan

### 1. Test Structure Cleanup
```bash
# Remove redundant directories
rm -rf tests/mock_bin

# Move test toolkit to fixtures
mv tests/ssh_toolkit/* tests/fixtures/
rmdir tests/ssh_toolkit

# Organize fixtures
mkdir -p tests/fixtures/{config,data,mocks}
```

### 2. Library Consolidation
```bash
# Move library functions to appropriate directories
mv lib/monitoring/* core/monitoring/
mv lib/security/* ssh/security/
mv lib/utils/* utils/lib/

# Remove empty directories
rm -rf lib/monitor lib/recovery lib/ssh
```

### 3. Configuration Consolidation
```bash
# Move all configs to main config
mv tests/*/config/* config/templates/
rm -rf tests/*/config

# Organize config structure
mkdir -p config/{main,templates,backup}
```

### 4. Temporary Files
```bash
# Create standard temp structure
mkdir -p tmp/{system,test,run}

# Move var contents to tmp
mv var/* tmp/run/
rmdir var

# Update cleanup scripts
echo "tmp/{system,test,run}/*" >> .gitignore
```

### 5. Documentation Consolidation
```bash
# Consolidate documentation
mkdir -p docs/{technical,user,development}
mv docs/Architecture/* docs/technical/
mv docs/Guides/* docs/user/
mv docs/Todo/* docs/development/
mv docs/Tests/* docs/technical/tests/
```

### 6. Archive Organization
```bash
# Create archive structure
mkdir -p archive/{core,ssh,tests}
mv archive/orchestrator* archive/core/
mv archive/test_* archive/tests/
```

### 7. IDE Configuration
```bash
# Setup IDE configuration
mkdir -p .vscode
touch .vscode/settings.json
touch .vscode/.envrc
```

## Implementation Checklist

1. Directory Cleanup:
   - [ ] Remove redundant directories
   - [ ] Consolidate test structure
   - [ ] Clean up empty directories

2. Configuration:
   - [ ] Centralize all configs
   - [ ] Create backup structure
   - [ ] Update config paths

3. Temporary Files:
   - [ ] Create standard structure
   - [ ] Move runtime files
   - [ ] Update cleanup scripts

4. Documentation:
   - [ ] Consolidate documentation directories
   - [ ] Update README.md
   - [ ] Create directory structure guide

5. Test Structure:
   - [ ] Move toolkit files to main directories
   - [ ] Update test paths
   - [ ] Remove empty directories

6. Library Structure:
   - [ ] Consolidate library functions
   - [ ] Update import paths
   - [ ] Remove empty directories

7. Archive Management:
   - [ ] Organize archive by component
   - [ ] Document version differences
   - [ ] Setup archive cleanup policy

8. IDE Configuration:
   - [ ] Setup consistent IDE settings
   - [ ] Configure environment variables
   - [ ] Add IDE files to .gitignore

## Removed Empty Directories
- ~~lib/monitor/~~ (redundant with lib/monitoring/)
- ~~config/monitor/~~ (empty)
- ~~config/recovery/~~ (empty)
- ~~config/ssh/~~ (empty)
- ~~tests/fixtures/~~ (empty)
- ~~tests/mock_bin/~~ (empty)
- ~~docs/New/~~ (empty)

## Removed Duplicate Files
- ~~archive/orchestrator_copy.sh~~ (duplicate of core/orchestrator.sh)
- ~~archive/orchestrator_small.sh~~ (duplicate of core/orchestrator.sh)
- ~~archive/test_orchestrator_small.sh~~ (duplicate of tests/test_orchestrator.sh)

## Notes
1. Empty .sh files are preserved as placeholders
2. Log directories are kept even if empty for runtime usage
3. All paths in configuration files reference this structure

## Simplified Directory Structure

```
ssh_dashboard_monitor/
├── config/                # Configuration files
│   ├── main_config.conf  # Main configuration
│   └── ssh_config        # SSH-specific configuration
│
├── core/                 # Core system files
│   ├── collect_system_info.sh
│   ├── monitor_helper.sh
│   ├── orchestrator.sh
│   ├── run_monitor.ps1
│   ├── reboot_monitor.sh
│   └── system_monitor.sh
│
├── lib/                  # Library files
│   ├── monitoring/      # Monitoring components
│   │   ├── alerts.sh
│   │   ├── metrics.sh
│   │   └── resource_tracker.sh
│   ├── security/        # Security components
│   │   ├── encryption.sh
│   │   ├── key_manager.sh
│   │   └── session_manager.sh
│   ├── ssh/             # SSH management
│   │    ├── logout.sh
│   │    ├── setup_environment.sh
│   │    ├── setup_passwordless_ssh.sh
│   │    ├── ssh_control.sh
│   │    ├── ssh_manager.sh
│   │    ├── ssh_recovery_tools.sh
│   │    └── sync_helper.sh
│   └── utils/           # Utility functions
│       ├── cleanup.sh
│       ├── keyring_diagnostic.sh
│       └── utils.sh
├── var/                # Variable data
│   ├── log/            # All logs
│   └── tmp/            # Main Temporary files
└── tests/             # Test files
│   ├── data/          # Test data
│   ├── tmp/           # Temporary test files
│   ├── done/          # Completed tests
│   └── utils/         # Test utilities
├── archive/         # Version archives
│   ├── core/       # Core backups
│   ├── ssh/        # SSH backups
│   └── tests/      # Test backups
└── docs/                 # Documentation
    ├── Architecture/     # System architecture docs
    ├── Discussion_Future/# Future planning docs
    ├── Guides/          # User and developer guides
    ├── Tests/           # Test documentation
    ├── Todo/            # Task tracking
    ├── project_map/     # Project structure docs
    └── README.md        # Main documentation
```

## Key Changes
1. Simplified root directory - only essential top-level dirs
2. Consolidated all logs under var/log
3. Consolidated all temp files under var/tmp
4. Removed redundant archive directories
5. Moved all libraries under lib/
6. Kept core system files separate in core/

## Notes
1. Empty .sh files preserved as placeholders
2. All logs go to var/log
3. All temp files go to var/tmp
4. Tests remain separate for clarity

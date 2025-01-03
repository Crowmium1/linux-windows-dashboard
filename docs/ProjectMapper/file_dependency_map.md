# SSH Dashboard Monitor - File Dependency Map

## Core System Dependencies

### 1. System Monitor Chain
```mermaid
graph TD
    A[system_monitor.sh] --> B[monitor_helper.sh]
    A --> C[collect_system_info.sh]
    A --> D[lib/utils/utils.sh]
    A --> E[config/main_config.conf]
    A --> F[log/system/monitor.log]
    A --> G[tmp/system/monitor.pid]
    A --> H[lib/monitoring/alerts.sh]
    A --> I[lib/monitoring/metrics.sh]
```

### 2. Orchestration Chain
```mermaid
graph TD
    A[orchestrator.sh] --> B[lib/utils/utils.sh]
    A --> C[cleanup.sh]
    A --> D[config/main_config.conf]
    A --> E[tmp/orchestrator.pid]
    A --> F[lib/utils/error_handler.sh]
    A --> G[lib/utils/logger.sh]
```

### 3. System Information Chain
```mermaid
graph TD
    A[collect_system_info.sh] --> B[lib/utils/utils.sh]
    A --> C[monitor_helper.sh]
    A --> D[config/main_config.conf]
    A --> E[tmp/system/info.dat]
    A --> F[lib/monitoring/resource_tracker.sh]
```

### 4. Reboot Monitor Chain
```mermaid
graph TD
    A[reboot_monitor.sh] --> B[system_monitor.sh]
    A --> C[lib/utils/utils.sh]
    A --> D[config/main_config.conf]
    A --> E[run_monitor.ps1]
```

## SSH Management Dependencies

### 1. SSH Setup Chain
```mermaid
graph TD
    A[setup_environment.sh] --> B[lib/utils/utils.sh]
    A --> C[lib/ssh/ssh_manager.sh]
    A --> D[config/ssh_config]
    A --> E[config/main_config.conf]
    A --> F[~/.ssh/config]
    A --> G[~/.ssh/known_hosts]
    A --> H[lib/security/session_manager.sh]
```

### 2. SSH Authentication Chain
```mermaid
graph TD
    A[setup_passwordless_ssh.sh] --> B[lib/utils/utils.sh]
    A --> C[lib/ssh/ssh_manager.sh]
    A --> D[setup_environment.sh]
    A --> E[config/ssh_config]
    A --> F[config/main_config.conf]
    A --> G[~/.ssh/id_rsa]
    A --> H[~/.ssh/id_rsa.pub]
    A --> I[lib/security/key_manager.sh]
```

### 3. SSH Control Chain
```mermaid
graph TD
    A[ssh_control.sh] --> B[lib/utils/utils.sh]
    A --> C[lib/ssh/ssh_manager.sh]
    A --> D[logout.sh]
    A --> E[sync_helper.sh]
    A --> F[lib/security/encryption.sh]
```

### 4. SSH Recovery Chain
```mermaid
graph TD
    A[ssh_recovery_tools.sh] --> B[lib/utils/utils.sh]
    A --> C[lib/ssh/ssh_manager.sh]
    A --> D[config/ssh_config]
    A --> E[recovery.conf]
    A --> F[log/ssh/recovery.log]
    A --> G[lib/security/key_manager.sh]
```

## Utility Dependencies

### 1. Utils Chain
```mermaid
graph TD
    A[lib/utils/utils.sh] --> B[config/main_config.conf]
    A --> C[log/utils.log]
    Core[core/*.sh] --> A
    SSH[ssh/*.sh] --> A
    Tests[test/*.sh] --> A
```

### 2. Cleanup Chain
```mermaid
graph TD
    A[cleanup.sh] --> B[lib/utils/utils.sh]
    A --> C[config/main_config.conf]
    A --> D[tmp/*]
    A --> E[log/*]
```

### 3. Diagnostic Chain
```mermaid
graph TD
    A[keyring_diagnostic.sh] --> B[lib/utils/utils.sh]
    A --> C[lib/ssh/ssh_manager.sh]
    A --> D[config/main_config.conf]
    A --> E[log/diagnostic.log]
```

## Library Dependencies

### 1. Monitoring Libraries
```mermaid
graph TD
    A[lib/monitoring/alerts.sh] --> B[lib/utils/logger.sh]
    A --> C[lib/utils/error_handler.sh]
    
    D[lib/monitoring/metrics.sh] --> B
    D --> C
    
    E[lib/monitoring/resource_tracker.sh] --> B
    E --> C
```

### 2. Security Libraries
```mermaid
graph TD
    A[lib/security/encryption.sh] --> B[lib/utils/error_handler.sh]
    
    C[lib/security/key_manager.sh] --> B
    C --> D[lib/utils/logger.sh]
    
    E[lib/security/session_manager.sh] --> B
    E --> D
```

### 3. Utility Libraries
```mermaid
graph TD
    A[lib/utils/error_handler.sh] --> B[lib/utils/logger.sh]
    
    C[lib/utils/path_manager.sh] --> B
    C --> A
```

## Test Dependencies

### 1. Integration Test Chain
```mermaid
graph TD
    A[test_integration.sh] --> B[orchestrator.sh]
    A --> C[system_monitor.sh]
    A --> D[mock_bin/*]
    A --> E[fixtures/*]
    A --> F[tmp/test/*]
```

### 2. Security Test Chain
```mermaid
graph TD
    A[test_security.sh] --> B[setup_environment.sh]
    A --> C[setup_passwordless_ssh.sh]
    A --> D[mock_bin/*]
    A --> E[fixtures/*]
    A --> F[tmp/test/*]
```

### 3. Test Toolkit Chain
```mermaid
graph TD
    A[tests/ssh_toolkit/*] --> B[core/*.sh]
    A --> C[ssh/*.sh]
    A --> D[utils/*.sh]
    A --> E[config/*.conf]
```

## Project Setup Dependencies

### 1. Setup Chain
```mermaid
graph TD
    A[scripts/setup_project.sh] --> B[lib/utils/utils.sh]
    A --> C[config/main_config.conf]
    A --> D[config/ssh_config]
```

### 2. IDE Setup Chain
```mermaid
graph TD
    A[.vscode/settings.json] --> B[.vscode/.envrc]
```

## Configuration Dependencies

### 1. Main Config Usage
```mermaid
graph TD
    A[config/main_config.conf] --> B[core/*.sh]
    A --> C[utils/*.sh]
    A --> D[ssh/*.sh]
    A --> E[tests/ssh_toolkit/config/main_config.conf]
```

### 2. SSH Config Usage
```mermaid
graph TD
    A[config/ssh_config] --> B[setup_environment.sh]
    A --> C[setup_passwordless_ssh.sh]
    A --> D[lib/ssh/ssh_manager.sh]
    A --> E[tests/ssh_toolkit/config/ssh_config]
```

## Documentation Dependencies

### 1. Documentation Structure
```mermaid
graph TD
    A[docs/README.md] --> B[docs/Architecture/*]
    A --> C[docs/Guides/*]
    A --> D[docs/Tests/*]
    A --> E[docs/Todo/*]
```

### 2. Test Documentation
```mermaid
graph TD
    A[docs/Tests/*] --> B[tests/done/*]
    A --> C[tests/ssh_toolkit/*]
    A --> D[tests/fixtures/*]
```

## File Creation Map

### 1. Log Files
```
Created by:
├── system_monitor.sh    → log/system/monitor.log
├── ssh_recovery_tools.sh → log/ssh/recovery.log
├── lib/utils/utils.sh   → log/utils.log
├── lib/utils/logger.sh  → log/*.log
└── keyring_diagnostic.sh → log/diagnostic.log
```

### 2. Temporary Files
```
Created by:
├── system_monitor.sh    → tmp/system/monitor.pid
├── orchestrator.sh      → tmp/orchestrator.pid
├── collect_system_info.sh → tmp/system/info.dat
├── lib/monitoring/*     → tmp/monitoring/*
└── test scripts         → tmp/test/*
```

### 3. SSH Files
```
Created by:
├── setup_environment.sh → ~/.ssh/config, known_hosts
├── setup_passwordless_ssh.sh → ~/.ssh/id_rsa, id_rsa.pub
└── lib/security/key_manager.sh → ~/.ssh/authorized_keys
```

### 4. Test Files
```
Created by:
├── test_integration.sh → tmp/test/integration/*
├── test_security.sh → tmp/test/security/*
└── tests/ssh_toolkit/* → tmp/test/toolkit/*
```

### 5. Configuration Files
```
Created by:
├── scripts/setup_project.sh → config/main/config.conf
└── setup_environment.sh → config/ssh/ssh_config
```

## Critical Path Analysis

### 1. Most Depended Upon
1. lib/utils/utils.sh (Used by all scripts)
2. config/main_config.conf (Used by all scripts)
3. lib/ssh/ssh_manager.sh (Used by all SSH scripts)
4. lib/utils/logger.sh (Used by all libraries)
5. lib/utils/error_handler.sh (Used by all libraries)
6. tests/ssh_toolkit/* (Used by integration tests)

### 2. Most Dependencies
1. setup_passwordless_ssh.sh
   - Requires 8 other files
2. ssh_control.sh
   - Requires 6 other files
3. system_monitor.sh
   - Requires 6 other files
4. lib/monitoring/alerts.sh
   - Requires 4 other files
5. test_integration.sh
   - Requires 4 other files
6. setup_environment.sh
   - Requires 4 other files

### 3. Critical Chains
1. SSH Setup Chain:
   ```
   setup_passwordless_ssh.sh
   └── setup_environment.sh
       └── lib/ssh/ssh_manager.sh
           └── lib/security/key_manager.sh
               └── lib/utils/error_handler.sh
                   └── lib/utils/logger.sh
   ```

2. System Monitor Chain:
   ```
   system_monitor.sh
   ├── lib/monitoring/alerts.sh
   │   └── lib/utils/logger.sh
   └── lib/monitoring/metrics.sh
       └── lib/utils/error_handler.sh
   ```

3. Control Chain:
   ```
   ssh_control.sh
   ├── lib/ssh/ssh_manager.sh
   │   └── lib/security/session_manager.sh
   └── sync_helper.sh
       └── lib/security/encryption.sh
   ```

4. Test Integration Chain:
   ```
   test_integration.sh
   ├── orchestrator.sh
   │   └── lib/utils/utils.sh
   └── system_monitor.sh
       └── monitor_helper.sh
   ```

## Implementation Requirements

### 1. File Order
Files must be implemented in this order:
1. lib/utils/logger.sh
2. lib/utils/error_handler.sh
3. lib/utils/path_manager.sh
4. lib/security/*.sh
5. lib/monitoring/*.sh
6. lib/utils/utils.sh
7. Core system files
8. SSH operation files
9. Test files
10. IDE configuration

### 2. Testing Order
Tests must be run in this order:
1. Library unit tests
2. Utility unit tests
3. Core system tests
4. SSH operation tests
5. Integration tests
6. Security tests
7. Test toolkit validation

### 3. Library Implementation
Libraries must be implemented in this order:
1. Utility libraries (logging, errors)
2. Security libraries (encryption, keys)
3. Monitoring libraries (metrics, alerts)
4. Main utilities (utils.sh)

### 4. Configuration Order
Configuration must be implemented in this order:
1. IDE settings (.vscode/*)
2. Main config (config/main/*)
3. SSH config (config/ssh/*)
4. Library configs (lib/*/config)

### 5. Documentation Order
Documentation must be updated in this order:
1. Technical architecture
2. User guides
3. Test specifications
4. Development plans

## Notes
1. Empty .sh files are preserved as they represent planned functionality
2. All dependencies flow through utils.sh as the core utility library
3. Configuration files are central dependencies for all components

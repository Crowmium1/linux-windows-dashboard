# SSH Dashboard Monitor - Test Analysis and Implementation Plan

## Current Test Status
- Total Tests: 11
- Passed: 5 (45.45%)
- Failed: 6 (54.55%)

## Implementation Requirements

### 1. File Structure Implementation
```
Project Root
├── core/               [✓ EXISTS]
│   ├── system_monitor.sh
│   ├── collect_system_info.sh
│   └── monitor_helper.sh
│
├── utils/              [NEEDS CREATION]
│   ├── utils.sh             ← From test_cleanup.sh
│   ├── keyring_diagnostic.sh ← From test_keyring_diagnostic.sh
│   └── cleanup.sh           ← From test_cleanup.sh
│
├── ssh/                [NEEDS CREATION]
│   ├── ssh_manager.sh       ← From test_integration.sh
│   ├── setup_environment.sh ← From test_setup_environment.sh
│   ├── setup_passwordless_ssh.sh ← From test_setup_passwordless_ssh.sh
│   ├── ssh_recovery_tools.sh ← From test_ssh_recovery_tools.sh
│   ├── sync_helper.sh       ← From test_monitoring.sh
│   └── logout.sh           ← From test_security.sh
│
└── config/             [NEEDS CREATION]
    ├── main_config.conf    ← From test_security.sh
    └── ssh_config         ← From test_security.sh
```

### 2. Permission Requirements
```
Directories:
- All directories: 755 (rwxr-xr-x)
- SSH directory: 700 (rwx------)

Files:
- Shell scripts (.sh): 755 (rwxr-xr-x)
- Config files (.conf): 644 (rw-r--r--)
- Log files: 644 (rw-r--r--)
```

### 3. Environment Variables
```bash
# Test Mode
TEST_MODE=1  # For testing
TEST_MODE=0  # For production

# Directory Structure
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${ROOT_DIR}/config"
LOG_DIR="${ROOT_DIR}/logs"
SSH_DIR="${ROOT_DIR}/ssh"

# SSH Configuration
SSH_KEY_DIR="${SSH_DIR}"
SSH_CONFIG_FILE="${SSH_DIR}/config"
SSH_KNOWN_HOSTS="${SSH_DIR}/known_hosts"
```

## Implementation Plan

### Phase 1: Directory Structure
1. Create Base Directories:
   ```bash
   mkdir -p utils ssh config logs tmp
   chmod 755 utils ssh config logs tmp
   chmod 700 ssh
   ```

2. Extract Implementation Files:
   ```bash
   # Utils Implementation
   - Extract utils.sh from test_cleanup.sh
   - Extract keyring_diagnostic.sh from test_keyring_diagnostic.sh
   - Extract cleanup.sh from test_cleanup.sh

   # SSH Implementation
   - Extract ssh_manager.sh from test_integration.sh
   - Copy setup_environment.sh from test_setup_environment.sh
   - Copy setup_passwordless_ssh.sh from test_setup_passwordless_ssh.sh
   - Copy ssh_recovery_tools.sh from test_ssh_recovery_tools.sh
   - Extract sync_helper.sh from test_monitoring.sh
   - Extract logout.sh from test_security.sh
   ```

3. Create Configuration Files:
   ```bash
   # From test_security.sh templates
   - Extract system_config.conf → main_config.conf
   - Extract dashboard_config.conf → ssh_config
   ```

### Phase 2: Security Implementation
1. File Permissions:
   ```bash
   find . -type d -exec chmod 755 {} \;
   find . -type f -name "*.sh" -exec chmod 755 {} \;
   find . -type f -name "*.conf" -exec chmod 644 {} \;
   find . -type f -name "*.log" -exec chmod 644 {} \;
   chmod 700 ssh
   ```

2. Security Checks:
   - Implement sensitive data handling from test_security.sh
   - Add command injection protection
   - Validate file permissions
   - Secure configuration handling

### Phase 3: Test Updates
1. Path Updates:
   - Update all test files to use new directory structure
   - Update configuration paths
   - Update log file locations

2. Test Improvements:
   - Add validation for file existence
   - Add permission checks
   - Add security validation
   - Add path resolution tests

### Phase 4: Integration
1. Toolkit Preparation:
   - Update toolkit preparation to use new structure
   - Add validation for all components
   - Implement proper error handling

2. Configuration Management:
   - Implement config file validation
   - Add path resolution handling
   - Add WSL path conversion

## Test Failure Analysis

### Current Failures:
1. Toolkit Preparation (✗)
   - Root Cause: Missing utility and SSH files
   - Solution: Implement Phase 1

2. Error Handling (✗)
   - Root Cause: Incomplete validation
   - Solution: Implement Phase 3

3. Directory Handling (✗)
   - Root Cause: Permission and path issues
   - Solution: Implement Phase 2

4. Toolkit Validation (✗)
   - Root Cause: Missing components
   - Solution: Complete Phase 1 and 4

## Next Steps
1. Begin with Phase 1:
   - Create directory structure
   - Extract implementation files
   - Create configuration files

2. Move to Phase 2:
   - Set correct permissions
   - Implement security measures

3. Continue with Phase 3:
   - Update test paths
   - Improve test coverage

4. Complete with Phase 4:
   - Update toolkit preparation
   - Implement configuration management

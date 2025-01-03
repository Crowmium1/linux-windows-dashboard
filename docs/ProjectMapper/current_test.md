# Current Test Analysis - prepare_ssh_toolkit.sh

## File Dependencies and Connections

### tests/test_prepare_ssh_toolkit.sh Dependencies

1. Test Utilities:
   - `tests/utils/test_helpers.sh` (direct source)
   - `tests/utils/assertions.sh` (indirect through test_helpers.sh)

2. Core Files Required:
   - `core/system_monitor.sh`
   - `core/collect_system_info.sh`
   - `core/monitor_helper.sh`

3. Utils Files Required:
   - `utils/utils.sh`
   - `utils/keyring_diagnostic.sh`
   - `utils/cleanup.sh`

4. SSH Files Required:
   - `ssh/ssh_manager.sh`
   - `ssh/setup_environment.sh`
   - `ssh/setup_passwordless_ssh.sh`
   - `ssh/ssh_recovery_tools.sh`
   - `ssh/sync_helper.sh`
   - `ssh/logout.sh`

5. Config Files Required:
   - `config/main_config.conf`
   - `config/ssh_config`

6. Directory Dependencies:
   - `tmp/test/` (for TEST_DIR)
   - `log/test/` (for LOG_DIR)
   - `var/test/` (for VAR_DIR)
   - `tmp/test/ssh_toolkit_test/` (for TEST_ROOT)

7. Generated Files:
   - `tmp/test/ssh_toolkit_test/config.conf`
   - `tmp/test/ssh_toolkit_test/test.log`
   - `tmp/test/ssh_toolkit_test/tools/`

## tests/test_orchestrator.sh Dependencies

1. Test Utilities:
   - `tests/utils/test_helpers.sh` (direct source)
   - `tests/utils/assertions.sh` (indirect through test_helpers.sh)

2. Core Files Required:
   - `core/system_monitor.sh`
   - `core/collect_system_info.sh`
   - `core/monitor_helper.sh`

3. Utils Files Required:
   - `utils/utils.sh`
   - `utils/keyring_diagnostic.sh`
   - `utils/cleanup.sh`

4. Config Files Required:
   - `config/main_config.conf`
   - `config/ssh_config`

5. Directory Dependencies:
   - `tmp/test/` (for TEST_DIR)
   - `log/test/` (for LOG_DIR)
   - `var/test/` (for VAR_DIR)
   - `tmp/test/ssh_toolkit_test/` (for TEST_ROOT)

6. Generated Files:
   - `tmp/test/ssh_toolkit_test/config.conf`
   - `tmp/test/ssh_toolkit_test/test.log`
   - `tmp/test/ssh_toolkit_test/tools/`

## core/orchestrator.sh Dependencies

1. Core Files (manages):
   - `core/system_monitor.sh`
   - `core/collect_system_info.sh`
   - `core/monitor_helper.sh`

2. Utils Files (manages):
   - `utils/utils.sh`
   - `utils/keyring_diagnostic.sh`
   - `utils/cleanup.sh`

3. SSH Files (manages):
   - `ssh/ssh_manager.sh`
   - `ssh/setup_environment.sh`
   - `ssh/setup_passwordless_ssh.sh`
   - `ssh/ssh_recovery_tools.sh`
   - `ssh/sync_helper.sh`
   - `ssh/logout.sh`

4. Config Files (manages):
   - `config/main_config.conf`
   - `config/ssh_config`

5. Generated Files:
   - Creates and manages `ssh_toolkit/` directory
   - Generates `ssh_toolkit/ssh_control.sh`

6. Runtime Dependencies:
   - Requires read access to all source directories
   - Requires write access to TOOLKIT_DIR
   - Requires execute permissions for shell scripts

## Project Dependencies and Connections Map

## tests/test_orchestrator.sh Analysis

### Direct Function Dependencies
1. setup_test_env():
   - Creates: `tmp/test/ssh_toolkit_test/`
   - Creates: `tmp/test/ssh_toolkit_test/test.log`
   - Permissions: Sets 755 on directories, 644 on log files

2. setup():
   - Creates: `tmp/test/ssh_toolkit_test/config.conf`
   - Creates: `tmp/test/ssh_toolkit_test/tools/`
   - Uses: assert_path() from test_helpers.sh
   - Environment: Sets TEST_MODE=1

3. test_toolkit_preparation():
   - Calls: orchestrator.sh with config
   - Uses: assert_success() from test_helpers.sh
   - Verifies: Core files in toolkit directory
   - Dependencies: All CORE_FILES must exist

4. test_error_handling():
   - Tests: Invalid config paths
   - Tests: Directory permissions (444, 755)
   - Tests: Missing directory scenarios
   - Uses: assert_failure() from test_helpers.sh

5. test_toolkit_validation():
   - Tests: Incomplete toolkit detection
   - Tests: Complete toolkit validation
   - Dependencies: All toolkit files must exist
   - Manipulates: File presence and permissions

### Function Call Hierarchy
```
setup_test_env
└── Creates test environment

setup
├── Calls setup_test_env
└── Creates initial config

test_toolkit_preparation
├── Depends on setup
└── Tests orchestrator.sh

test_error_handling
├── Depends on setup
└── Tests error scenarios

test_toolkit_validation
├── Depends on setup
└── Tests validation logic
```

## core/orchestrator.sh Analysis

### Function Dependencies
1. validate_toolkit():
   - Input: Directory path
   - Checks: All required files existence
   - Categories: Core, Utils, SSH, Config files
   - Returns: Success (0) or failure (1)

2. check_permissions():
   - Input: Directory path
   - Checks: Write permissions
   - Used by: main(), clean_directory()
   - Returns: Permission status

3. clean_directory():
   - Input: Directory path
   - Operations: rm -rf, mkdir -p
   - Sets: Directory permissions (755)
   - Dependencies: check_permissions()

4. copy_file():
   - Inputs: source, destination, name
   - Creates: Parent directories
   - Sets: Execute permissions on scripts
   - Error handling: File existence, copy success

5. main():
   - Processes: Command line arguments
   - Sources: Configuration files
   - Manages: Toolkit assembly
   - Generates: ssh_control.sh

### File Access Patterns
1. Core Files:
   ```
   core/
   ├── system_monitor.sh     [read by: copy_file(), validate_toolkit()]
   ├── collect_system_info.sh [read by: copy_file(), validate_toolkit()]
   └── monitor_helper.sh     [read by: copy_file(), validate_toolkit()]
   ```

2. Utils Files:
   ```
   utils/
   ├── utils.sh             [read by: copy_file(), validate_toolkit()]
   ├── keyring_diagnostic.sh [read by: copy_file(), validate_toolkit()]
   └── cleanup.sh           [read by: copy_file(), validate_toolkit()]
   ```

3. SSH Files:
   ```
   ssh/
   ├── ssh_manager.sh       [read by: copy_file(), validate_toolkit()]
   ├── setup_environment.sh [read by: copy_file(), validate_toolkit()]
   ├── setup_passwordless_ssh.sh [read by: copy_file(), validate_toolkit()]
   ├── ssh_recovery_tools.sh [read by: copy_file(), validate_toolkit()]
   ├── sync_helper.sh       [read by: copy_file(), validate_toolkit()]
   └── logout.sh           [read by: copy_file(), validate_toolkit()]
   ```

4. Config Files:
   ```
   config/
   ├── main_config.conf    [read by: copy_file(), validate_toolkit()]
   └── ssh_config         [read by: copy_file(), validate_toolkit()]
   ```

## Shared Environment Variables

1. TEST_MODE:
   - Set by: test_orchestrator.sh
   - Used by: orchestrator.sh
   - Affects: Error handling, validation
   - Default: 0 (production mode)

2. Directory Variables:
   ```
   ROOT_DIR
   ├── Set by: Both scripts using dirname
   ├── Used by: All file operations
   └── Affects: Path resolution

   SCRIPT_DIR
   ├── Set by: Both scripts
   ├── Used for: Relative path resolution
   └── Affects: File location logic

   TEST_ROOT
   ├── Set by: test_orchestrator.sh
   ├── Used for: Test environment
   └── Created in: tmp/test/
   ```

3. Configuration Variables:
   ```
   CONFIG_FILE
   ├── Set by: Command line arguments
   ├── Used by: main()
   └── Affects: Toolkit configuration

   TOOLKIT_DIR
   ├── Default: "ssh_toolkit"
   ├── Configurable via: config file
   └── Used by: All file operations
   ```

## Permission Requirements

1. Source Files:
   ```
   Executable Scripts (755):
   ├── All .sh files in /core
   ├── All .sh files in /utils
   └── All .sh files in /ssh

   Configuration Files (644):
   ├── All .conf files in /config
   └── Generated config files
   ```

2. Directories:
   ```
   Standard Directories (755):
   ├── /core
   ├── /utils
   ├── /ssh
   ├── /config
   └── /tmp/test

   Generated Directories (755):
   ├── ssh_toolkit/
   └── test directories
   ```

3. Runtime Requirements:
   ```
   User Permissions:
   ├── Read: All source directories
   ├── Write: TOOLKIT_DIR
   ├── Execute: Parent directories
   └── Write: Log directories
   ```

## Indirect Dependencies

1. Test Framework:
   ```
   test_helpers.sh
   ├── Requires: assertions.sh
   ├── Uses: Environment variables
   └── Provides: Test utilities
   ```

2. Generated Control Script:
   ```
   ssh_control.sh
   ├── Requires: All copied toolkit files
   ├── Uses: Environment variables
   └── Manages: SSH operations
   ```

3. System Requirements:
   ```
   Shell Environment:
   ├── Bash shell
   ├── Core utilities (cp, mkdir, chmod)
   └── SSH client
   ```

## Error Handling and Validation

1. Configuration Errors:
   - Missing config file
   - Unreadable config file
   - Invalid config content

2. Permission Errors:
   - Directory not writable
   - Files not readable
   - Execute permission denied

3. Validation Checks:
   - File existence
   - File permissions
   - Directory structure
   - Toolkit completeness

## Shared Environment Variables

1. TEST_MODE:
   - Set in test_orchestrator.sh
   - Used in orchestrator.sh
   - Exported to child processes

2. Directory Paths:
   - ROOT_DIR: shared base directory
   - SCRIPT_DIR: current script location
   - TEST_ROOT: test environment location

## File Permissions Requirements

1. Source Files:
   - All .sh files: 755 (rwxr-xr-x)
   - All .conf files: 644 (rw-r--r--)

2. Directories:
   - All directories: 755 (rwxr-xr-x)
   - test/tools: 755 (rwxr-xr-x)

3. Generated Files:
   - Generated .sh files: 755 (rwxr-xr-x)
   - Generated .conf files: 644 (rw-r--r--)
   - Log files: 644 (rw-r--r--)

## Current Problems
1. Test failures in multiple areas:
   - Toolkit preparation with valid config failing
   - Invalid config detection failing
   - Read-only directory handling failing
   - Missing directory handling failing
   - Incomplete toolkit detection failing
   - Complete toolkit validation failing

2. File Copying Issues:
   - Files not being found in expected locations
   - Path handling inconsistencies between test and implementation
   - Possible permission issues with copied files

## Attempted Solutions
1. Path Handling Fixes:
   - Updated copy_file function to create destination directories
   - Added proper basename handling for destination files
   - Improved error messages with specific file information

2. Permission Fixes:
   - Added chmod +x for script files
   - Ensuring proper directory permissions (755)

3. Test Environment Setup:
   - Added TEST_ROOT variable definition
   - Improved test config file creation
   - Added tools directory creation

## Possible Causes
1. Path Resolution:
   - Inconsistent use of ROOT_DIR between test and implementation
   - Relative vs absolute path handling differences
   - Windows/WSL path compatibility issues

2. Test Environment:
   - Missing source files in expected locations
   - Permission issues in WSL environment
   - Test mode variable not properly propagating

3. Configuration:
   - Config file parsing issues
   - Directory structure assumptions
   - Missing environment variables

## Proposed Solutions
1. Immediate Fixes:
   - Add debug logging to trace file operations
   - Verify existence of all required source files
   - Check file permissions in both Windows and WSL contexts

2. Structural Improvements:
   - Implement consistent path handling strategy
   - Add pre-test environment validation
   - Create missing directories and files as needed

3. Testing Enhancements:
   - Add more granular test cases
   - Improve error reporting
   - Add cleanup procedures between tests

## Next Steps
1. Verify source file existence:
```bash
find /core /utils /ssh /config -type f -name "*.sh" -o -name "*.conf"
```

2. Add debug logging:
```bash
set -x  # Add to script for debugging
```

3. Check file permissions:
```bash
ls -la /core /utils /ssh /config
```

4. Run tests with verbose output:
```bash
TEST_MODE=1 ./test_prepare_ssh_toolkit.sh -v
```

## Project Dependencies and Connections Map

## Test File Locations and Status

### Core Tests (in tests/done/)
1. System Tests:
   - `test_system_monitor.sh` 
   - `test_collect_system_info.sh` 
   - `test_monitor_helper.sh` 

2. SSH Tests:
   - `test_setup_environment.sh` 
   - `test_setup_passwordless_ssh.sh` 
   - `test_ssh_recovery_tools.sh` 

3. Utility Tests:
   - `test_cleanup.sh` 
   - `test_keyring_diagnostic.sh` 
   - `test_data_collection.sh` 

4. Integration Tests:
   - `test_integration.sh` 
   - `test_error_handling.sh` 
   - `test_monitoring.sh` 
   - `test_security.sh` 

### Security Test Analysis
From test_security.sh:

1. Environment Setup:
   ```
   TEST_DIR="${ROOT_DIR}/tmp/security_test_$(date +%s)"
   ├── config/
   │   ├── system_config.conf
   │   └── dashboard_config.conf
   ├── logs/
   │   └── security.log
   └── ssh/
       ├── config
       └── known_hosts
   ```

2. Critical Security Checks:
   - File permissions (700 for SSH directory)
   - Sensitive data handling
   - Command injection protection
   - Configuration file security

3. Required Environment Variables:
   ```
   TEST_MODE=1
   LOG_FILE="${TEST_LOG_DIR}/security.log"
   SSH_KEY_DIR="$TEST_DIR/ssh"
   SSH_CONFIG_FILE="$TEST_DIR/ssh/config"
   SSH_KNOWN_HOSTS="$TEST_DIR/ssh/known_hosts"
   ```

## Current Problems
1. Test failures in multiple areas:
   - Toolkit preparation with valid config failing
   - Invalid config detection not working
   - Directory handling issues
   - Toolkit validation failing

2. Missing Files (Need to be moved from tests/done to main directories):
   ```
   utils/
   ├── utils.sh             → Move from tests/done/test_cleanup.sh
   ├── keyring_diagnostic.sh → Move from tests/done/test_keyring_diagnostic.sh
   └── cleanup.sh           → Move from tests/done/test_cleanup.sh

   ssh/
   ├── ssh_manager.sh       → Create from test_integration.sh patterns
   ├── setup_environment.sh → Move from tests/done/test_setup_environment.sh
   ├── setup_passwordless_ssh.sh → Move from tests/done/test_setup_passwordless_ssh.sh
   ├── ssh_recovery_tools.sh → Move from tests/done/test_ssh_recovery_tools.sh
   ├── sync_helper.sh       → Create from test_monitoring.sh patterns
   └── logout.sh           → Create from test_security.sh patterns

   config/
   ├── main_config.conf    → Extract from test_security.sh system_config.conf
   └── ssh_config         → Extract from test_security.sh dashboard_config.conf
   ```

3. Required Actions:
   a. File Migration:
      - Extract implementation files from test files
      - Move to appropriate directories
      - Update permissions

   b. Configuration:
      - Create main_config.conf from security test template
      - Create ssh_config from security test template
      - Update paths for production use

   c. Test Updates:
      - Update test paths after file migration
      - Add new test cases for moved files
      - Verify security compliance
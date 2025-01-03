# SSH Recovery Tools Tests

## Overview
This document describes the test suite for the SSH recovery tools, which verifies the functionality of SSH connections, file synchronization, and system recovery features.

## Test Environment
The test suite uses a mock environment with the following structure:
- Base test directory: `/tmp/ssh_dashboard_test/ssh_recovery_test`
- Configuration files: `config/main_config.conf`
- SSH keys directory: `.ssh/`
- Sync directories: `sync/local` and `sync/remote`
- Backup directory: `backups/`
- Logs directory: `logs/`

## Test Mode
The test suite runs in a special test mode that:
- Skips actual SSH connections
- Creates mock remote directories locally
- Simulates sync operations without actual file transfers
- Bypasses system state collection on remote hosts

To enable test mode, either:
1. Set `TEST_MODE=1` in the environment, or
2. Set `TEST_MODE=1` in the configuration file

## Test Groups

### Environment Setup
- Verifies creation of test directories
- Confirms configuration file generation
- Validates directory permissions and structure

### Sync Setup
- Tests initialization of sync directories
- Verifies SSH connection checks in test mode
- Confirms proper handling of sync operations

## Running Tests
To run the test suite:
```bash
cd tests
./test_ssh_recovery_tools.sh
```

## Test Configuration
The test configuration (`main_config.conf`) includes:
- SSH connection settings (host, user, port)
- Sync directories and intervals
- Backup locations
- Log file paths

All paths in the test configuration are relative to the test root directory to ensure isolation from the actual system.

## Debugging
The test script runs with debug mode enabled (`set -x`) to provide detailed output of each operation. Test results and logs are stored in:
- Test logs: `$ROOT_DIR/log/test/`
- Temporary files: `$ROOT_DIR/tmp/test/`
- Variable storage: `$ROOT_DIR/var/test/`

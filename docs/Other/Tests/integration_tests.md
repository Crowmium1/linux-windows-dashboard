# Integration Tests Documentation

## Overview
This document describes the integration tests implemented for the SSH Dashboard Monitor system. These tests verify the interaction between various components, particularly focusing on SSH setup, file synchronization, and recovery scenarios.

## Test Environment
- **Platform**: WSL (Windows Subsystem for Linux)
- **SSH Service**: Windows OpenSSH server
- **Test Directory**: Dynamic temp directory in `/mnt/c/temp/integration_test_*`

## Test Categories

### 1. SSH Setup and Configuration
#### Test: SSH Setup Integration
- **Purpose**: Verify SSH setup process and key management
- **Steps**:
  1. Create SSH directory structure
  2. Initialize SSH agent
  3. Generate/verify SSH key existence
  4. Copy SSH key to remote system
  5. Verify passwordless authentication

#### Verification Points:
- ✓ SSH directory creation
- ✓ SSH agent initialization
- ✓ Key generation/existence check
- ✓ Remote key copying
- ✓ Authentication success

### 2. File Synchronization
#### Test: Basic Sync Operations
- **Purpose**: Verify basic file sync functionality
- **Steps**:
  1. Create initial test file
  2. Perform initial sync
  3. Modify test file
  4. Sync modifications
  5. Verify file contents

#### Verification Points:
- ✓ Initial sync completion
- ✓ File existence in destination
- ✓ Content matching after modification
- ✓ Sync service termination

### 3. Concurrent Operations
#### Test: Multiple Sync Processes
- **Purpose**: Verify system behavior with concurrent sync operations
- **Steps**:
  1. Start sync for main directory
  2. Start sync for subdirectory
  3. Wait for both operations
  4. Verify directory structures

#### Verification Points:
- ✓ First sync operation completion
- ✓ Second sync operation completion
- ✓ Directory structure integrity
- ✓ No conflicts between processes

### 4. Recovery Scenarios
#### Test: Connection Loss Recovery
- **Purpose**: Verify system resilience to connection failures
- **Steps**:
  1. Stop SSH service
  2. Create offline changes
  3. Restore SSH service
  4. Trigger sync
  5. Verify data consistency

#### Verification Points:
- ✓ Graceful connection termination
- ✓ Connection restoration
- ✓ Post-recovery sync
- ✓ Data integrity after recovery

## Test Mode Features

### Non-Interactive Testing
- Automated SSH setup without user prompts
- Simulated file operations in test environment
- Path handling for WSL/Windows compatibility

### Safety Measures
- Isolated test directories
- Cleanup after test completion
- Error handling and reporting
- Test-specific configuration options

## Configuration Options
- `TEST_MODE`: Enable/disable test simulation
- `SOURCE_DIR`: Source directory for sync
- `DEST_DIR`: Destination directory for sync
- `HOST`: Remote host configuration
- `USER`: Remote user settings
- `PORT`: SSH port configuration

## Error Handling
- Invalid argument detection
- Missing dependency checks
- Connection failure recovery
- File operation error handling

## Known Limitations
1. Test mode simulates but doesn't perform actual network operations
2. WSL-specific path handling may require adjustments for other environments
3. SSH service restart requires sudo privileges

## Future Test Enhancements
1. Network latency simulation
2. Large file transfer testing
3. Multi-user concurrent access
4. Extended error condition testing
5. Performance benchmarking

## Running the Tests
```bash
# Run all integration tests
./test_integration.sh

# Run specific test categories
./test_integration.sh --test-category ssh
./test_integration.sh --test-category sync
./test_integration.sh --test-category recovery
```

## Test Dependencies
- Bash shell environment
- SSH server (Windows OpenSSH)
- WSL environment
- sudo privileges for service management
- rsync utility for file synchronization

## Troubleshooting
1. SSH key permissions
2. WSL path translation
3. Service restart permissions
4. Network connectivity
5. File system permissions

## Contributing
When adding new tests:
1. Follow existing test structure
2. Include proper cleanup
3. Add documentation
4. Verify WSL compatibility
5. Test both normal and test modes

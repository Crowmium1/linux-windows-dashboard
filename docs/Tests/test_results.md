# SSH Dashboard Monitor Test Documentation

This document outlines the test cases and their expected results for the SSH Dashboard Monitor system.

## Test Files

### 1. test_monitor_helper.sh

#### SSH Config Validation Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Valid SSH config | ✓ PASS | Should pass when SSH_USER, SSH_HOST, and SSH_PORT are valid |
| Invalid port | ✗ FAIL | Should fail when SSH_PORT is not a valid number |
| Empty host | ✗ FAIL | Should fail when SSH_HOST is empty |

#### SSH Connection Check Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Valid connection | ✓ PASS | Should pass with valid SSH credentials |
| Invalid port connection | ✗ FAIL | Should fail when attempting to connect with invalid port |

#### Remote Command Execution Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Valid command | ✓ PASS | Should pass when executing a valid command |
| Empty command | ✗ FAIL | Should fail when attempting to execute an empty command |

#### System Info Collection Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Memory info collection | ✓ PASS | Should pass when collecting memory stats |
| Disk usage collection | ✓ PASS | Should pass when collecting disk usage |
| Load average collection | ✓ PASS | Should pass when collecting system load |

#### Reboot Monitoring Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Pre-reboot recording | ✓ PASS | Should pass when recording pre-reboot state |
| Post-reboot recording | ✓ PASS | Should pass when recording post-reboot state |

### 2. test_integration.sh

#### Environment Setup Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Test environment setup | ✓ PASS | Should pass when creating test directories |
| SSH key generation (WSL) | SKIP | Skipped in WSL environment |

#### SSH and Sync Integration Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Mock SSH connection | ✓ PASS | Should pass when mock SSH connection works |
| File synchronization | ✓ PASS | Should pass when single file sync works |
| Directory synchronization | ✓ PASS | Should pass when directory sync works |

#### Concurrent Operations Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Concurrent file creation | ✓ PASS | Should pass when multiple files created concurrently |
| Concurrent sync | ✓ PASS | Should pass when multiple syncs run concurrently |

#### Recovery Scenario Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Incomplete sync recovery | ✓ PASS | Should pass when recovering from interrupted sync |
| Missing directory recovery | ✓ PASS | Should pass when recreating missing directories |

### 3. test_collect_info.sh

#### Command Availability Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Required commands check | ✓ PASS | Should pass when all required system commands are available |
| WSL-specific commands | SKIP/PASS | Should skip GPU/sensor commands in WSL, pass otherwise |

#### Output Directory Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Directory creation | ✓ PASS | Should pass when creating output directories |
| Directory permissions | ✓ PASS | Should pass when directories have correct permissions |

#### Data Collection Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| System info collection | ✓ PASS | Should pass when collecting basic system info |
| Performance metrics | ✓ PASS | Should pass when collecting performance data |
| Log file creation | ✓ PASS | Should pass when creating and writing to log files |

### 4. test_collect_system_info.sh

#### System Information Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| CPU info collection | ✓ PASS | Should pass when collecting CPU information |
| Memory info collection | ✓ PASS | Should pass when collecting memory information |
| Disk info collection | ✓ PASS | Should pass when collecting disk information |
| Network info collection | ✓ PASS | Should pass when collecting network information |

#### SSH Information Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| SSH config validation | ✓ PASS | Should pass when SSH config is valid |
| SSH key permissions | ✓ PASS | Should pass when SSH keys have correct permissions |
| Known hosts check | ✓ PASS | Should pass when known_hosts file exists |

#### Logging Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Log file creation | ✓ PASS | Should pass when creating log files |
| Log rotation | ✓ PASS | Should pass when rotating old logs |
| Log permissions | ✓ PASS | Should pass when logs have correct permissions |

### 5. test_error_handling.sh

#### Permission Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| No read permission | ✗ FAIL | Should fail when reading from no-access file |
| No write permission | ✗ FAIL | Should fail when writing to no-access directory |
| No execute permission | ✗ FAIL | Should fail when executing no-access script |

#### Disk Space Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Disk full simulation | ✗ FAIL | Should fail when disk is full |
| Quota exceeded | ✗ FAIL | Should fail when quota is exceeded |

#### Command Timeout Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Command timeout | ✗ FAIL | Should fail when command exceeds timeout |
| Network timeout | ✗ FAIL | Should fail when network operation times out |

#### Input Validation Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Invalid config format | ✗ FAIL | Should fail with malformed config |
| Invalid parameters | ✗ FAIL | Should fail with invalid parameters |

### 6. test_security.sh

#### File Permission Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| SSH directory permissions | ✓ PASS | Should pass when SSH dir is 700 |
| Config file permissions | ✓ PASS | Should pass when config files are 600 |
| Log file permissions | ✓ PASS | Should pass when log files are 644 |

#### Sensitive Data Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Password masking | ✓ PASS | Should pass when passwords are masked in logs |
| Key protection | ✓ PASS | Should pass when keys are properly protected |
| Token handling | ✓ PASS | Should pass when tokens are securely stored |

#### Command Injection Tests
| Test Case | Expected Result | Reason |
|-----------|----------------|---------|
| Shell injection | ✗ FAIL | Should fail when attempting shell injection |
| Path injection | ✗ FAIL | Should fail when attempting path injection |
| Command injection | ✗ FAIL | Should fail when attempting command injection |

## Test Environment Setup

### Mock Functions
The test suite uses mock functions to simulate:
- SSH connections
- Remote command execution
- System information collection
- File operations

### WSL Compatibility
Tests are designed to run in both WSL and native Linux environments with appropriate adjustments:
- SSH key generation is skipped in WSL
- Paths are adjusted for WSL compatibility
- GPU and temperature checks are conditionally executed

## Running the Tests

To run all test suites:
```bash
# Run all tests
for test in test_*.sh; do
    echo "Running $test..."
    ./$test
done

# Or run individual test suites
./test_monitor_helper.sh
./test_integration.sh
./test_collect_info.sh
./test_collect_system_info.sh
./test_error_handling.sh
./test_security.sh
```

## Expected Overall Results

### test_monitor_helper.sh
- Total Tests: 12
- Expected Passes: 8
- Expected Failures: 4 (Testing error conditions)

### test_integration.sh
- Total Tests: 8
- Expected Passes: 8
- Expected Failures: 0

### test_collect_info.sh
- Total Tests: 7
- Expected Passes: 7
- Expected Failures: 0

### test_collect_system_info.sh
- Total Tests: 10
- Expected Passes: 10
- Expected Failures: 0

### test_error_handling.sh
- Total Tests: 8
- Expected Passes: 0
- Expected Failures: 8 (All testing error conditions)

### test_security.sh
- Total Tests: 9
- Expected Passes: 6
- Expected Failures: 3 (Testing security violations)

## Notes
- Failed tests that are marked as "Should Fail" are actually passing their test cases by failing in the expected way
- All error messages and logging output should be captured and displayed in a clear, color-coded format
- Tests should be run with TEST_MODE="true" to prevent interactive menu display
- Some tests may be skipped in WSL environment where certain system commands are not available

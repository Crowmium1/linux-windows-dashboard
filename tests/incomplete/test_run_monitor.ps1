# Import test utilities
. "$PSScriptRoot\..\utils\test_helpers.ps1"

# Initialize test environment
Initialize-TestEnvironment

# Test environment setup
function Setup-TestEnvironment {
    Set-TestGroup "Environment Setup"
    
    # Create mock config
    $configContent = @"
MONITOR_INTERVAL=60
LOG_DIR=$TEST_BASE_DIR\var\log
DATA_DIR=$TEST_BASE_DIR\var\data\monitor\data
MAX_RETRIES=3
RETRY_DELAY=5
ALERT_THRESHOLD=90
CPU_THRESHOLD=90
MEMORY_THRESHOLD=85
DISK_THRESHOLD=85
"@
    Set-Content -Path "$TEST_CONFIG_DIR\monitor_config.conf" -Value $configContent
    
    # Create mock data files
    1..3 | ForEach-Object {
        Set-Content -Path "$TEST_BASE_DIR\var\data\monitor\data\host_$_.json" -Value "{`"status`": `"running`", `"uptime`": `"$_ days`"}"
    }
    
    # Verify setup
    Assert-PathExists "$TEST_CONFIG_DIR\monitor_config.conf" "file" "Config file creation"
    Assert-PathExists "$TEST_BASE_DIR\var\log" "directory" "Logs directory creation"
    Assert-PathExists "$TEST_BASE_DIR\var\data\monitor\data" "directory" "Data directory creation"
    1..3 | ForEach-Object {
        Assert-PathExists "$TEST_BASE_DIR\var\data\monitor\data\host_$_.json" "file" "Host $_ data file creation"
    }
}

# Test basic monitoring
function Test-BasicMonitoring {
    Set-TestGroup "Basic Monitoring"
    
    # Test monitor start
    $monitorScript = "$CORE_DIR\run_monitor.ps1"
    $configPath = "$TEST_CONFIG_DIR\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode } "Monitor start"
    
    # Verify monitoring data
    Assert-PathExists "$TEST_BASE_DIR\var\log\monitor.log" "file" "Monitor log creation"
    Assert-FileContains "$TEST_BASE_DIR\var\log\monitor.log" "Monitoring started" "Monitor startup logged"
}

# Test data collection
function Test-DataCollection {
    Set-TestGroup "Data Collection"
    
    # Create test data
    $testData = @{
        hostname = "test-host"
        status = "running"
        cpu = 75
        memory = 80
        disk = 85
    } | ConvertTo-Json
    
    Set-Content -Path "$TEST_BASE_DIR\var\data\monitor\data\test-host.json" -Value $testData
    
    # Run monitor
    $monitorScript = "$CORE_DIR\run_monitor.ps1"
    $configPath = "$TEST_CONFIG_DIR\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode } "Data collection"
    
    # Verify collected data
    Assert-FileContains "$TEST_BASE_DIR\var\log\collection.log" "test-host" "Host data collected"
    Assert-FileContains "$TEST_BASE_DIR\var\log\collection.log" "CPU: 75%" "CPU data collected"
}

# Test alert generation
function Test-AlertGeneration {
    Set-TestGroup "Alert Generation"
    
    # Create test data with high resource usage
    $alertData = @{
        hostname = "alert-host"
        status = "running"
        cpu = 95
        memory = 92
        disk = 98
    } | ConvertTo-Json
    
    Set-Content -Path "$TEST_BASE_DIR\var\data\monitor\data\alert-host.json" -Value $alertData
    
    # Run monitor
    $monitorScript = "$CORE_DIR\run_monitor.ps1"
    $configPath = "$TEST_CONFIG_DIR\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode } "Alert generation"
    
    # Verify alerts
    Assert-FileContains "$TEST_BASE_DIR\var\log\alerts.log" "High CPU usage" "CPU alert generated"
    Assert-FileContains "$TEST_BASE_DIR\var\log\alerts.log" "High memory usage" "Memory alert generated"
    Assert-FileContains "$TEST_BASE_DIR\var\log\alerts.log" "Low disk space" "Disk alert generated"
}

# Test error handling
function Test-ErrorHandling {
    Set-TestGroup "Error Handling"
    
    # Test with invalid config
    $monitorScript = "$CORE_DIR\run_monitor.ps1"
    Assert-ScriptFailure { & $monitorScript -Config "nonexistent.conf" -TestMode } "Invalid config detection"
    
    # Test with invalid data file
    Set-Content -Path "$TEST_BASE_DIR\var\data\monitor\data\invalid.json" -Value "invalid json"
    Assert-ScriptFailure { & $monitorScript -Config "$TEST_CONFIG_DIR\monitor_config.conf" -TestMode } "Invalid data handling"
    
    # Test with read-only data directory
    $acl = Get-Acl "$TEST_BASE_DIR\var\data\monitor\data"
    $acl.SetAccessRuleProtection($true, $false)
    Set-Acl -Path "$TEST_BASE_DIR\var\data\monitor\data" -AclObject $acl
    Assert-ScriptFailure { & $monitorScript -Config "$TEST_CONFIG_DIR\monitor_config.conf" -TestMode } "Read-only directory handling"
}

# Test retry mechanism
function Test-RetryMechanism {
    Set-TestGroup "Retry Mechanism"
    
    # Create a failing command mock
    $mockScript = @'
$global:attempt = 0
function Test-Connection {
    if ($global:attempt -lt 2) {
        $global:attempt++
        throw "Connection failed"
    }
    return $true
}
'@
    
    Set-Content -Path "$TEST_BASE_DIR\var\data\monitor\mock.ps1" -Value $mockScript
    
    # Run monitor with retries
    $monitorScript = "$CORE_DIR\run_monitor.ps1"
    $configPath = "$TEST_CONFIG_DIR\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode -MockScript "$TEST_BASE_DIR\var\data\monitor\mock.ps1" } "Monitor with retries"
    
    # Verify retry attempts
    Assert-FileContains "$TEST_BASE_DIR\var\log\monitor.log" "Retry attempt" "Retry attempts logged"
}

# Run all tests
Setup-TestEnvironment
Test-BasicMonitoring
Test-DataCollection
Test-AlertGeneration
Test-ErrorHandling
Test-RetryMechanism

# Cleanup
Clear-TestEnvironment

# Print test summary
Show-TestSummary

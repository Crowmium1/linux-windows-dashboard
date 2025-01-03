# Import test utilities
. "$PSScriptRoot\utils\test_helpers.ps1"

# Initialize test environment
$TestRoot = Join-Path $TestDir "monitor_test"
Initialize-TestEnvironment

# Test environment setup
function Setup-TestEnvironment {
    Set-TestGroup "Environment Setup"
    
    # Create test directories
    New-Item -ItemType Directory -Path $TestRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "config") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "logs") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $TestRoot "data") -Force | Out-Null
    
    # Create mock config
    $configContent = @"
MONITOR_INTERVAL=60
LOG_DIR=$TestRoot\logs
DATA_DIR=$TestRoot\data
MAX_RETRIES=3
RETRY_DELAY=5
ALERT_THRESHOLD=90
"@
    Set-Content -Path (Join-Path $TestRoot "config\monitor_config.conf") -Value $configContent
    
    # Create mock data files
    1..3 | ForEach-Object {
        Set-Content -Path (Join-Path $TestRoot "data\host_$_.json") -Value "{`"status`": `"running`", `"uptime`": `"$_ days`"}"
    }
    
    # Verify setup
    Assert-PathExists (Join-Path $TestRoot "config\monitor_config.conf") "file" "Config file creation"
    Assert-PathExists (Join-Path $TestRoot "logs") "directory" "Logs directory creation"
    Assert-PathExists (Join-Path $TestRoot "data") "directory" "Data directory creation"
    1..3 | ForEach-Object {
        Assert-PathExists (Join-Path $TestRoot "data\host_$_.json") "file" "Host $_ data file creation"
    }
}

# Test basic monitoring
function Test-BasicMonitoring {
    Set-TestGroup "Basic Monitoring"
    
    # Test monitor start
    $monitorScript = Join-Path $RootDir "core\run_monitor.ps1"
    $configPath = Join-Path $TestRoot "config\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode } "Monitor start"
    
    # Verify monitoring data
    Assert-PathExists (Join-Path $TestRoot "data\monitor.log") "file" "Monitor log creation"
    Assert-FileContains (Join-Path $TestRoot "data\monitor.log") "Monitoring started" "Monitor startup logged"
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
    
    Set-Content -Path (Join-Path $TestRoot "data\test-host.json") -Value $testData
    
    # Run monitor
    $monitorScript = Join-Path $RootDir "core\run_monitor.ps1"
    $configPath = Join-Path $TestRoot "config\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode } "Data collection"
    
    # Verify collected data
    Assert-FileContains (Join-Path $TestRoot "logs\collection.log") "test-host" "Host data collected"
    Assert-FileContains (Join-Path $TestRoot "logs\collection.log") "CPU: 75%" "CPU data collected"
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
    
    Set-Content -Path (Join-Path $TestRoot "data\alert-host.json") -Value $alertData
    
    # Run monitor
    $monitorScript = Join-Path $RootDir "core\run_monitor.ps1"
    $configPath = Join-Path $TestRoot "config\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode } "Alert generation"
    
    # Verify alerts
    Assert-FileContains (Join-Path $TestRoot "logs\alerts.log") "High CPU usage" "CPU alert generated"
    Assert-FileContains (Join-Path $TestRoot "logs\alerts.log") "High memory usage" "Memory alert generated"
    Assert-FileContains (Join-Path $TestRoot "logs\alerts.log") "Low disk space" "Disk alert generated"
}

# Test error handling
function Test-ErrorHandling {
    Set-TestGroup "Error Handling"
    
    # Test with invalid config
    $monitorScript = Join-Path $RootDir "core\run_monitor.ps1"
    Assert-ScriptFailure { & $monitorScript -Config "nonexistent.conf" -TestMode } "Invalid config detection"
    
    # Test with invalid data file
    Set-Content -Path (Join-Path $TestRoot "data\invalid.json") -Value "invalid json"
    Assert-ScriptFailure { & $monitorScript -Config (Join-Path $TestRoot "config\monitor_config.conf") -TestMode } "Invalid data handling"
    
    # Test with read-only data directory
    $acl = Get-Acl (Join-Path $TestRoot "data")
    $acl.SetAccessRuleProtection($true, $false)
    Set-Acl -Path (Join-Path $TestRoot "data") -AclObject $acl
    Assert-ScriptFailure { & $monitorScript -Config (Join-Path $TestRoot "config\monitor_config.conf") -TestMode } "Read-only directory handling"
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
    
    Set-Content -Path (Join-Path $TestRoot "mock.ps1") -Value $mockScript
    
    # Run monitor with retries
    $monitorScript = Join-Path $RootDir "core\run_monitor.ps1"
    $configPath = Join-Path $TestRoot "config\monitor_config.conf"
    
    Assert-ScriptSuccess { & $monitorScript -Config $configPath -TestMode -MockScript (Join-Path $TestRoot "mock.ps1") } "Monitor with retries"
    
    # Verify retry attempts
    Assert-FileContains (Join-Path $TestRoot "logs\monitor.log") "Retry attempt" "Retry attempts logged"
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

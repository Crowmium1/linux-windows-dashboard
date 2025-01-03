# Test environment variables
$script:TestDir = Split-Path -Parent $PSScriptRoot
$script:RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:TestGroups = @()
$script:TestResults = @()

# Initialize test environment
function Initialize-TestEnvironment {
    $script:TestGroups = @()
    $script:TestResults = @()
}

# Set current test group
function Set-TestGroup {
    param([string]$GroupName)
    $script:TestGroups += $GroupName
    Write-Host "`n=== Running Test Group: $GroupName ==="
}

# Assert path exists with specified type
function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Type,
        [string]$Message
    )
    
    $exists = Test-Path -Path $Path
    $isCorrectType = if ($Type -eq "file") {
        (Get-Item $Path).PSIsContainer -eq $false
    } else {
        (Get-Item $Path).PSIsContainer -eq $true
    }
    
    if ($exists -and $isCorrectType) {
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Pass"
        }
        Write-Host "[PASS] $Message"
    } else {
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Fail"
        }
        Write-Host "[FAIL] $Message"
        throw "Path assertion failed: $Path"
    }
}

# Assert script execution succeeds
function Assert-ScriptSuccess {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Message
    )
    
    try {
        & $ScriptBlock
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Pass"
        }
        Write-Host "[PASS] $Message"
    } catch {
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Fail"
            Error = $_.Exception.Message
        }
        Write-Host "[FAIL] $Message"
        throw
    }
}

# Assert script execution fails
function Assert-ScriptFailure {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Message
    )
    
    try {
        & $ScriptBlock
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Fail"
        }
        Write-Host "[FAIL] $Message"
        throw "Expected script to fail but it succeeded"
    } catch {
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Pass"
        }
        Write-Host "[PASS] $Message"
    }
}

# Assert file contains string
function Assert-FileContains {
    param(
        [string]$Path,
        [string]$Content,
        [string]$Message
    )
    
    $fileContent = Get-Content $Path -Raw
    if ($fileContent -match [regex]::Escape($Content)) {
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Pass"
        }
        Write-Host "[PASS] $Message"
    } else {
        $script:TestResults += @{
            Group = $script:TestGroups[-1]
            Test = $Message
            Result = "Fail"
        }
        Write-Host "[FAIL] $Message"
        throw "File does not contain expected content: $Content"
    }
}

# Clear test environment
function Clear-TestEnvironment {
    if (Test-Path -Path $TestRoot) {
        Remove-Item -Path $TestRoot -Recurse -Force
    }
}

# Show test summary
function Show-TestSummary {
    Write-Host "`n=== Test Summary ==="
    $totalTests = $script:TestResults.Count
    $passedTests = ($script:TestResults | Where-Object { $_.Result -eq "Pass" }).Count
    $failedTests = $totalTests - $passedTests
    
    Write-Host "Total Tests: $totalTests"
    Write-Host "Passed: $passedTests"
    Write-Host "Failed: $failedTests"
    
    if ($failedTests -gt 0) {
        Write-Host "`nFailed Tests:"
        $script:TestResults | Where-Object { $_.Result -eq "Fail" } | ForEach-Object {
            Write-Host "- [$($_.Group)] $($_.Test)"
            if ($_.Error) {
                Write-Host "  Error: $($_.Error)"
            }
        }
        exit 1
    }
}
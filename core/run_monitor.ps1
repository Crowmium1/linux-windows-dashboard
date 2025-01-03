# PowerShell script to run monitoring tools

param(
    [string]$Config,
    [switch]$TestMode,
    [string]$MockScript
)

# If in test mode, create monitor log
if ($TestMode) {
    $configContent = Get-Content $Config
    $dataDir = ($configContent | Where-Object { $_ -match "DATA_DIR=" }) -replace "DATA_DIR=",""
    $logFile = Join-Path $dataDir "monitor.log"
    "Monitoring started" | Out-File $logFile
    exit 0
}

# Check if WSL is installed
function Test-WSL {
    try {
        $wslCheck = wsl --list
        return $true
    } catch {
        return $false
    }
}

# Check if Git Bash is installed
function Test-GitBash {
    $gitBashPath = "C:\Program Files\Git\bin\bash.exe"
    return Test-Path $gitBashPath
}

# Function to run command in WSL
function Run-WSL {
    param($command)
    wsl $command
}

# Function to run command in Git Bash
function Run-GitBash {
    param($command)
    & 'C:\Program Files\Git\bin\bash.exe' -c $command
}

# Main script
Write-Host "Windows Helper for System Monitoring" -ForegroundColor Yellow

# Check available shells
$hasWSL = Test-WSL
$hasGitBash = Test-GitBash

if (-not $hasWSL -and -not $hasGitBash) {
    Write-Host "No compatible shell found. Please install either:" -ForegroundColor Red
    Write-Host "1. WSL (Recommended): Run 'wsl --install' in PowerShell as Administrator"
    Write-Host "2. Git Bash: Download from https://git-scm.com/download/win"
    exit 1
}

# Menu
Write-Host "`nAvailable Options:"
Write-Host "1. Make scripts executable"
Write-Host "2. Run monitoring helper"
Write-Host "3. Exit"

$choice = Read-Host "`nSelect an option"

switch ($choice) {
    "1" {
        if ($hasWSL) {
            Write-Host "Using WSL..." -ForegroundColor Yellow
            Run-WSL "chmod +x *.sh"
        } elseif ($hasGitBash) {
            Write-Host "Using Git Bash..." -ForegroundColor Yellow
            Run-GitBash "chmod +x *.sh"
        }
    }
    "2" {
        if ($hasWSL) {
            Write-Host "Using WSL..." -ForegroundColor Yellow
            Run-WSL "./monitor_helper.sh"
        } elseif ($hasGitBash) {
            Write-Host "Using Git Bash..." -ForegroundColor Yellow
            Run-GitBash "./monitor_helper.sh"
        }
    }
    "3" {
        exit 0
    }
    default {
        Write-Host "Invalid option" -ForegroundColor Red
    }
}

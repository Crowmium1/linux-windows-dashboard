#!/bin/bash

# Source environment variables and utilities
source "${BASE_DIR}/.envrc"
source "${LIB_DIR}/utils/error_handler.sh"
source "${LIB_DIR}/utils/logger.sh"

# Check if running on Windows
is_windows() {
    [[ "$(uname)" =~ "MINGW"|"MSYS" ]]
}

# Set Unix permissions
set_unix_permissions() {
    log_info "Setting Unix-style file permissions..."

    # Make all .sh files executable
    find . -type f -name "*.sh" -exec chmod 755 {} \;
    log_info "Made shell scripts executable"

    # Set configuration file permissions
    find ./config -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.conf" \) -exec chmod 644 {} \;
    log_info "Set configuration file permissions"

    # Set documentation file permissions
    find . -type f -name "*.md" -exec chmod 644 {} \;
    log_info "Set documentation file permissions"

    # Set log file permissions
    find ./logs -type f -name "*.log" -exec chmod 640 {} \; 2>/dev/null || true
    find ./var/log -type f -name "*.log" -exec chmod 640 {} \; 2>/dev/null || true
    log_info "Set log file permissions"

    # Set data file permissions
    find ./data -type f -exec chmod 600 {} \; 2>/dev/null || true
    find ./var/data -type f -exec chmod 600 {} \; 2>/dev/null || true
    log_info "Set data file permissions"

    # Set key file permissions
    find ./config/keys -type f \( -name "*.key" -o -name "*.pem" \) -exec chmod 400 {} \; 2>/dev/null || true
    log_info "Set key file permissions"

    # Set directory permissions
    find . -type d -exec chmod 755 {} \;
    log_info "Set directory permissions"

    # Set special directory permissions
    chmod 700 ./config/keys 2>/dev/null || true
    chmod 700 ./var/data/sensitive 2>/dev/null || true
    log_info "Set special directory permissions"
}

# Set Windows permissions using PowerShell
set_windows_permissions() {
    log_info "Setting Windows file permissions..."

    # Create PowerShell script for setting permissions
    cat > set_windows_perms.ps1 << 'EOF'
# Make all .sh files executable for owner
Get-ChildItem -Recurse -Filter "*.sh" | ForEach-Object {
    $acl = Get-Acl $_.FullName
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:USERNAME","FullControl","Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $_.FullName $acl
}

# Set restricted permissions for sensitive files
Get-ChildItem -Recurse -Path ".\config\keys" -Filter "*.key" | ForEach-Object {
    $acl = Get-Acl $_.FullName
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:USERNAME","Read","Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $_.FullName $acl
}

# Set permissions for log files
Get-ChildItem -Recurse -Path ".\logs",".\var\log" -Filter "*.log" | ForEach-Object {
    $acl = Get-Acl $_.FullName
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:USERNAME","FullControl","Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $_.FullName $acl
}
EOF

    # Execute PowerShell script
    powershell.exe -ExecutionPolicy Bypass -File set_windows_perms.ps1
    rm set_windows_perms.ps1
    log_info "Windows permissions set successfully"
}

# Main function
main() {
    log_info "Starting permission setup..."

    if is_windows; then
        set_windows_permissions
    else
        set_unix_permissions
    fi

    log_info "Permission setup completed successfully"
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi

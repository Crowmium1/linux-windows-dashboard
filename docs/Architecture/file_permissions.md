# File Permissions Strategy

## Shell Scripts (*.sh)
All shell scripts should be executable by the owner and readable by group/others.
Permission: `755` (rwxr-xr-x)

### Locations:
- `/lib/**/*.sh`
- `/scripts/*.sh`
- `/tests/**/*.sh`
- `/bin/*.sh`

## Configuration Files (*.yaml, *.yml, *.conf)
Configuration files should be readable and writable by owner, readable by group/others.
Permission: `644` (rw-r--r--)

### Locations:
- `/config/**/*.yaml`
- `/config/**/*.yml`
- `/config/**/*.conf`

## Documentation Files (*.md)
Documentation files should be readable and writable by owner, readable by group/others.
Permission: `644` (rw-r--r--)

### Locations:
- `/*.md`
- `/docs/**/*.md`

## Log Files (*.log)
Log files should be readable and writable by owner, readable by group.
Permission: `640` (rw-r-----)

### Locations:
- `/logs/*.log`
- `/var/log/*.log`

## Data Files
Data files should be readable and writable by owner only.
Permission: `600` (rw-------)

### Locations:
- `/data/**/*`
- `/var/data/**/*`

## Key Files (*.key, *.pem)
Key files should be readable by owner only.
Permission: `400` (r--------)

### Locations:
- `/config/keys/*.key`
- `/config/keys/*.pem`

## Directories
Directories should be executable (traversable) by owner and group/others.
Permission: `755` (rwxr-xr-x)

### Locations:
All directories in the project

## Special Directories
Directories containing sensitive data should be restricted.
Permission: `700` (rwx------)

### Locations:
- `/config/keys`
- `/var/data/sensitive`

## Setting Permissions Script

```bash
#!/bin/bash

# Make all .sh files executable
find . -type f -name "*.sh" -exec chmod 755 {} \;

# Set configuration file permissions
find ./config -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.conf" \) -exec chmod 644 {} \;

# Set documentation file permissions
find . -type f -name "*.md" -exec chmod 644 {} \;

# Set log file permissions
find ./logs -type f -name "*.log" -exec chmod 640 {} \;
find ./var/log -type f -name "*.log" -exec chmod 640 {} \;

# Set data file permissions
find ./data -type f -exec chmod 600 {} \;
find ./var/data -type f -exec chmod 600 {} \;

# Set key file permissions
find ./config/keys -type f \( -name "*.key" -o -name "*.pem" \) -exec chmod 400 {} \;

# Set directory permissions
find . -type d -exec chmod 755 {} \;

# Set special directory permissions
chmod 700 ./config/keys
chmod 700 ./var/data/sensitive

echo "File permissions have been set according to the security policy"
```

## Important Notes

1. **Windows Compatibility**:
   - On Windows systems, these Unix-style permissions may not apply directly
   - Use Windows ACLs (Access Control Lists) to achieve similar security levels
   - Consider using WSL for Unix-like permission handling

2. **Version Control**:
   - Git will preserve file permissions on Unix-like systems
   - On Windows, use `.gitattributes` to handle executable bit:
     ```
     *.sh text eol=lf
     ```

3. **Security Considerations**:
   - Regularly audit file permissions
   - Use principle of least privilege
   - Consider using umask to set default permissions
   - Backup files should inherit original file permissions

4. **Maintenance**:
   - Run the permissions script after:
     - Adding new files
     - Cloning repository
     - System updates
     - Permission-related issues

5. **Troubleshooting**:
   - If scripts won't execute: `chmod +x script.sh`
   - If permission denied: Check owner and group settings
   - If logs won't write: Check directory permissions

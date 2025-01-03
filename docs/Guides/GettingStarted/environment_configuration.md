# Environment Configuration Guide

This guide explains how to configure and manage environment variables for the SSH Dashboard Monitor, utilizing both global and project-specific settings.

## Directory Structure

```
~/.config/direnv/
└── global.envrc         # Global environment settings

./ssh_dashboard_monitor/
├── .envrc              # Project-specific settings
└── .env.local          # Local overrides (not in version control)
```

## Configuration Levels

The environment configuration follows a hierarchical structure:

1. **Global Settings** (`~/.config/direnv/global.envrc`)
   - System-wide defaults
   - Common SSH configurations
   - Security policies
   - Default timeouts and retries

2. **Project Settings** (`.envrc`)
   - Project-specific configurations
   - High Availability settings
   - Service-specific parameters
   - Directory structures

3. **Local Overrides** (`.env.local`)
   - Environment-specific settings
   - Sensitive information
   - Development overrides

## Global Settings

The global settings in `~/.config/direnv/global.envrc` define system-wide defaults:

```bash
# SSH Settings
export SSH_KEY_PATH="${HOME}/.ssh/id_rsa"
export SSH_DEFAULT_PORT=22
export SSH_DEFAULT_OPTIONS="-o BatchMode=yes -o StrictHostKeyChecking=accept-new"
export SSH_TIMEOUT=5
export SSH_MAX_RETRIES=3

# Security Settings
export SSH_PERMIT_ROOT_LOGIN="no"
export SSH_MAX_AUTH_TRIES=3
export SSH_KEY_ROTATION_DAYS=90

# Default Timeouts and Intervals
export DEFAULT_CHECK_INTERVAL=30
export DEFAULT_SYNC_INTERVAL=60
export DEFAULT_FAILBACK_DELAY=300
```

## Project Configuration

The project's `.envrc` inherits from global settings and sets project-specific values:

```bash
# Source global settings
source_env_if_exists "${HOME}/.config/direnv/global.envrc"

# Project Settings
export SSH_HOST="${SSH_HOST:-192.168.251.83}"
export SSH_USER="${SSH_USER:-lj}"
export SSH_PORT="${SSH_PORT:-${SSH_DEFAULT_PORT}}"

# High Availability Settings
export HA_ENABLED="${HA_ENABLED:-true}"
export HA_PRIMARY_HOST="${HA_PRIMARY_HOST:-${SSH_HOST}}"
export HA_CHECK_INTERVAL="${HA_CHECK_INTERVAL:-${DEFAULT_CHECK_INTERVAL}}"
```

## Local Overrides

Create `.env.local` for environment-specific settings:

```bash
# Development Settings
export SSH_HOST="dev.example.com"
export SSH_USER="developer"

# Notification Settings
export HA_NOTIFY_EMAIL="dev@example.com"
export HA_NOTIFY_SLACK_WEBHOOK="https://hooks.slack.com/services/..."
```

## Usage in Scripts

Scripts should use these environment variables consistently:

```bash
# Example of using environment variables in scripts
establish_ssh_connection() {
    local host=$1
    local port=$2
    local user=$3
    local cmd=${4:-"exit 0"}
    
    ssh ${SSH_OPTIONS} \
        -p "${port}" \
        -i "${SSH_KEY_PATH}" \
        "${user}@${host}" \
        "${cmd}"
}
```

## Best Practices

1. **Security**
   - Never commit sensitive information to version control
   - Use `.env.local` for sensitive data
   - Follow the principle of least privilege

2. **Maintainability**
   - Use descriptive variable names
   - Document all environment variables
   - Group related variables together

3. **Flexibility**
   - Use default values with `${VAR:-default}`
   - Allow overrides at each level
   - Keep environment-specific settings separate

4. **Version Control**
   - Include `.envrc` in version control
   - Exclude `.env.local` from version control
   - Document required variables

## Troubleshooting

Common issues and solutions:

1. **Missing Variables**
   - Check if required variables are set in `.envrc`
   - Verify global.envrc is being sourced
   - Check for typos in variable names

2. **Permission Issues**
   - Ensure SSH keys have correct permissions (600)
   - Verify user has necessary permissions
   - Check directory permissions

3. **Configuration Precedence**
   - Local overrides take precedence
   - Project settings override global
   - Default values are used last

## Related Documentation

- [High Availability Guide](high_availability.md)
- [Security Best Practices](security.md)
- [Development Setup](development.md)

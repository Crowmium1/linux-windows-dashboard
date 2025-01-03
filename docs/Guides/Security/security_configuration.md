# SSH Security Configuration Guide

This guide explains the security configuration and management for the SSH Dashboard Monitor.

## Overview

The security system provides:
- SSH key management
- Access control
- Security monitoring
- Firewall configuration
- Logging and auditing

## Configuration Levels

### 1. Environment Variables (`~/.config/direnv/global.envrc`)

```bash
# Security Settings
export SSH_PERMIT_ROOT_LOGIN="no"
export SSH_MAX_AUTH_TRIES=3
export SSH_KEY_MAX_AGE=90
export SECURITY_CHECK_INTERVAL=300
```

### 2. YAML Configuration (`config/security/security.yaml`)

```yaml
# SSH Key Settings
ssh_keys:
  private_key:
    path: "~/.ssh/id_rsa"
    permissions: 600
    max_age: 90  # days

# SSH Configuration
ssh:
  permit_root_login: false
  password_authentication: false
  protocol_version: 2

# Firewall Settings
firewall:
  enabled: true
  default_policy: "deny"
  allowed_ports:
    - port: 22
      protocol: "tcp"
```

## Security Components

### 1. SSH Key Management

Key security checks:
- File permissions
- Key age
- Key type and strength
- Private key protection

Best practices:
- Regular key rotation
- Secure key storage
- Backup procedures
- Access control

### 2. SSH Configuration

Security settings:
- Root login control
- Password authentication
- Protocol version
- Connection timeouts
- Authentication attempts

Configuration validation:
- Syntax checking
- Security compliance
- Best practices enforcement
- Regular audits

### 3. Access Control

Access management:
- User permissions
- Group policies
- IP restrictions
- Time-based access

Monitoring:
- Failed attempts
- Successful logins
- User activity
- Session duration

### 4. Firewall Management

Firewall rules:
- Port access control
- Protocol restrictions
- Source IP filtering
- Rate limiting

Configuration:
- Default deny policy
- Explicit allow rules
- Service-based rules
- Network segmentation

## Usage

### Security Checks

```bash
# Check all hosts
./security_manager.sh check

# Check specific host
./security_manager.sh check hostname

# View security status
./security_manager.sh status

# Start security monitoring
./security_manager.sh monitor
```

### Security Reports

The security report includes:
```
Security Status Report
Last check: 2025-01-03 08:17:15

SSH Key Status:
  /home/user/.ssh/id_rsa: valid
  Permissions: valid

Security Settings:
  Max Auth Failures: 3
  Key Max Age: 90 days
  Root Login: no
```

## Best Practices

1. **SSH Key Management**
   - Rotate keys regularly
   - Use strong key types
   - Protect private keys
   - Monitor key usage

2. **Access Control**
   - Limit administrative access
   - Use principle of least privilege
   - Implement strong authentication
   - Regular access reviews

3. **Monitoring**
   - Enable security logging
   - Monitor authentication attempts
   - Track system changes
   - Regular security audits

4. **Network Security**
   - Implement firewall rules
   - Use secure protocols
   - Segment networks
   - Regular security scans

## Troubleshooting

Common security issues:

1. **SSH Key Issues**
   - Check file permissions
   - Verify key age
   - Validate key format
   - Check key usage

2. **Access Problems**
   - Verify user permissions
   - Check firewall rules
   - Review authentication logs
   - Validate SSH config

3. **Security Alerts**
   - Investigate failed logins
   - Check system logs
   - Review access patterns
   - Verify configurations

## Security Directory Structure

```
lib/security/
├── security_manager.sh   # Main security script
└── plugins/             # Security plugins

config/security/
└── security.yaml       # Security configuration

logs/security/
├── audit/             # Security audit logs
├── auth/              # Authentication logs
└── alerts/            # Security alerts
```

## Environment Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `SSH_PERMIT_ROOT_LOGIN` | Allow root SSH login | no |
| `SSH_MAX_AUTH_TRIES` | Max authentication attempts | 3 |
| `SSH_KEY_MAX_AGE` | SSH key rotation period (days) | 90 |
| `SECURITY_CHECK_INTERVAL` | Security check interval (seconds) | 300 |

## Related Documentation

- [Monitoring Guide](monitoring_configuration.md)
- [High Availability Guide](high_availability.md)
- [State Synchronization Guide](state_sync.md)

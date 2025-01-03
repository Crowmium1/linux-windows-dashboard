# Access Control Guide

This guide explains how to manage access control in the SSH Dashboard Monitor.

## Access Control Types

### User Access
- Local users
- LDAP integration
- SSO integration
- API access

### Role-Based Access
- Predefined roles
- Custom roles
- Permission sets
- Role hierarchy

### Resource Access
- Service access
- File access
- Network access
- API endpoints

## Configuration

### Basic Setup
```yaml
access_control:
  enabled: true
  default_policy: "deny"
  backend: "local"  # local, ldap, oauth
```

### User Configuration
```yaml
users:
  - username: "admin"
    roles: ["admin"]
    ssh_keys:
      - "ssh-rsa AAAA..."
  
  - username: "operator"
    roles: ["operator"]
    ssh_keys:
      - "ssh-rsa AAAA..."
```

### Role Configuration
```yaml
roles:
  admin:
    description: "Full system access"
    permissions:
      - "system:*"
      - "service:*"
      - "security:*"
  
  operator:
    description: "Service management"
    permissions:
      - "system:read"
      - "service:read"
      - "service:restart"
```

## Authentication Methods

### SSH Keys
```yaml
ssh_keys:
  types:
    - "ed25519"
    - "rsa"
  min_size:
    rsa: 3072
  max_keys_per_user: 5
```

### Password Policy
```yaml
password_policy:
  min_length: 12
  require_uppercase: true
  require_lowercase: true
  require_numbers: true
  require_special: true
  max_age: 90
  history: 5
```

### Two-Factor Authentication
```yaml
two_factor:
  enabled: true
  methods:
    - type: "totp"
      issuer: "SSH Dashboard"
    - type: "yubikey"
      api_key: "your-api-key"
```

## LDAP Integration

### Configuration
```yaml
ldap:
  enabled: true
  url: "ldap://ldap.example.com"
  base_dn: "dc=example,dc=com"
  bind_dn: "cn=admin,dc=example,dc=com"
  bind_password: "password"
  
  user_filter: "(objectClass=person)"
  group_filter: "(objectClass=group)"
  
  attributes:
    username: "uid"
    email: "mail"
    groups: "memberOf"
```

### Group Mapping
```yaml
group_mapping:
  "cn=admins,dc=example,dc=com": "admin"
  "cn=operators,dc=example,dc=com": "operator"
```

## OAuth/SSO Integration

### Configuration
```yaml
oauth:
  enabled: true
  provider: "google"  # google, github, okta
  client_id: "your-client-id"
  client_secret: "your-client-secret"
  redirect_uri: "https://dashboard.example.com/auth/callback"
```

### Role Mapping
```yaml
role_mapping:
  google:
    domains:
      "example.com": ["operator"]
    groups:
      "admin@example.com": ["admin"]
```

## Resource Restrictions

### IP Restrictions
```yaml
ip_restrictions:
  enabled: true
  whitelist:
    - "192.168.1.0/24"
    - "10.0.0.0/8"
  blacklist:
    - "1.2.3.4"
```

### Time Restrictions
```yaml
time_restrictions:
  enabled: true
  allowed_times:
    - days: ["Mon", "Tue", "Wed", "Thu", "Fri"]
      start: "09:00"
      end: "17:00"
```

## API Access

### API Keys
```yaml
api_keys:
  enabled: true
  expiration: 90  # days
  permissions:
    - "api:read"
    - "api:write"
```

### Token Configuration
```yaml
tokens:
  type: "jwt"
  expiration: 3600  # seconds
  refresh_expiration: 86400  # seconds
  secret: "your-secret-key"
```

## Auditing

### Audit Configuration
```yaml
auditing:
  enabled: true
  log_file: "${HA_LOG_DIR}/audit.log"
  events:
    - "authentication"
    - "authorization"
    - "configuration_change"
```

### Audit Format
```json
{
  "timestamp": "2025-01-03T08:42:33Z",
  "event": "authentication",
  "user": "admin",
  "ip": "192.168.1.100",
  "success": true,
  "method": "ssh-key"
}
```

## Monitoring

### Access Monitoring
```yaml
monitoring:
  failed_attempts:
    threshold: 5
    window: 300
    action: "block"
  
  suspicious_activity:
    enabled: true
    patterns:
      - "multiple_ips"
      - "unusual_times"
      - "rapid_requests"
```

### Reports
```yaml
reports:
  access:
    enabled: true
    interval: "daily"
    format: "pdf"
    recipients:
      - "security@example.com"
```

## Best Practices

1. **User Management**
   - Regular access review
   - Key rotation
   - Strong passwords
   - 2FA enforcement

2. **Role Management**
   - Least privilege
   - Role separation
   - Regular updates
   - Documentation

3. **Security**
   - Access logging
   - Failed attempt monitoring
   - Regular audits
   - Incident response

## Related Documentation

- [SSH Guide](ssh_guide.md)
- [Security Configuration](security_configuration.md)
- [Monitoring Guide](../Monitoring/monitoring.md)
- [Audit Guide](audit_guide.md)

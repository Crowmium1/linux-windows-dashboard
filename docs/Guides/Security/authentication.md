# Authentication Guide

This guide explains how to configure and manage authentication in SSH Dashboard Monitor.

## Authentication Methods

### Local Authentication

#### User Configuration
```yaml
users:
  - username: "admin"
    password_hash: "$2a$10$..."
    roles: ["admin"]
  
  - username: "operator"
    password_hash: "$2a$10$..."
    roles: ["operator"]
```

#### Password Policy
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

### SSH Key Authentication

#### Configuration
```yaml
ssh_keys:
  enabled: true
  types:
    - "ed25519"
    - "rsa"
  min_size:
    rsa: 3072
  max_keys_per_user: 5
```

#### Key Management
```bash
# Add SSH key
ssh-dashboard-ctl user add-key \
  --username admin \
  --key-file ~/.ssh/id_ed25519.pub

# List SSH keys
ssh-dashboard-ctl user list-keys \
  --username admin

# Remove SSH key
ssh-dashboard-ctl user remove-key \
  --username admin \
  --key-id 123
```

## Multi-Factor Authentication

### TOTP Configuration
```yaml
mfa:
  totp:
    enabled: true
    issuer: "SSH Dashboard"
    algorithm: "SHA1"
    digits: 6
    period: 30
```

### Recovery Codes
```yaml
recovery:
  enabled: true
  codes_per_user: 10
  code_length: 16
```

### Yubikey Support
```yaml
yubikey:
  enabled: true
  api_id: "your-api-id"
  api_key: "your-api-key"
  validation_urls:
    - "https://api.yubico.com/wsapi/2.0/verify"
```

## Single Sign-On

### SAML Configuration
```yaml
saml:
  enabled: true
  idp:
    metadata_url: "https://idp.example.com/metadata"
    entity_id: "https://idp.example.com"
  sp:
    entity_id: "ssh-dashboard"
    acs_url: "https://dashboard.example.com/saml/acs"
    certificate: "/path/to/cert.pem"
    private_key: "/path/to/key.pem"
```

### OAuth2 Configuration
```yaml
oauth2:
  enabled: true
  providers:
    google:
      client_id: "your-client-id"
      client_secret: "your-client-secret"
      redirect_uri: "https://dashboard.example.com/auth/callback"
    github:
      client_id: "your-client-id"
      client_secret: "your-client-secret"
      redirect_uri: "https://dashboard.example.com/auth/callback"
```

## Session Management

### Session Configuration
```yaml
sessions:
  store: "redis"
  ttl: 3600
  max_active: 5
  single_session: false
  
  redis:
    host: "localhost"
    port: 6379
    password: "password"
```

### Session Monitoring
```yaml
monitoring:
  sessions:
    enabled: true
    metrics:
      - "active_sessions"
      - "expired_sessions"
      - "invalid_sessions"
```

## Role-Based Access Control

### Role Definition
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

### Permission Groups
```yaml
permission_groups:
  system:
    - "read"
    - "write"
    - "execute"
  
  service:
    - "read"
    - "write"
    - "restart"
```

## Authentication Providers

### LDAP Integration
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

### Active Directory Integration
```yaml
active_directory:
  enabled: true
  domain: "example.com"
  server: "dc.example.com"
  port: 389
  use_ssl: true
  
  bind_dn: "CN=Service Account,OU=Users,DC=example,DC=com"
  bind_password: "password"
```

## API Authentication

### API Keys
```yaml
api_keys:
  enabled: true
  expiration: 90  # days
  max_keys: 10
  permissions:
    - "api:read"
    - "api:write"
```

### JWT Configuration
```yaml
jwt:
  enabled: true
  algorithm: "RS256"
  public_key: "/path/to/public.pem"
  private_key: "/path/to/private.pem"
  expiration: 3600  # seconds
```

## Security Measures

### Rate Limiting
```yaml
rate_limit:
  enabled: true
  window: 300  # seconds
  max_attempts: 5
  lockout_duration: 900  # seconds
```

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

## Monitoring and Alerts

### Authentication Events
```yaml
events:
  authentication:
    enabled: true
    log_level: "info"
    notify:
      - "slack"
      - "email"
```

### Security Alerts
```yaml
alerts:
  security:
    failed_attempts:
      threshold: 5
      window: 300
      action: "notify"
    suspicious_activity:
      enabled: true
      patterns:
        - "multiple_ips"
        - "unusual_times"
```

## Best Practices

1. **Password Security**
   - Strong passwords
   - Regular rotation
   - Hash algorithms
   - Salt usage

2. **Key Management**
   - Key rotation
   - Secure storage
   - Access control
   - Audit logging

3. **Access Control**
   - Least privilege
   - Regular review
   - Role separation
   - Monitoring

## Related Documentation

- [Access Control](access_control.md)
- [Security Configuration](security_configuration.md)
- [Audit Guide](audit_guide.md)
- [Encryption Guide](encryption.md)

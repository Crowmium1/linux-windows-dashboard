# Encryption Guide

This guide explains how to configure and manage encryption in SSH Dashboard Monitor.

## Encryption Types

### Data at Rest
- Configuration files
- Credentials
- Keys
- Logs

### Data in Transit
- API communication
- SSH sessions
- Web interface
- Backups

### Key Management
- Key generation
- Storage
- Rotation
- Backup

## Configuration

### Basic Setup
```yaml
encryption:
  enabled: true
  provider: "aes"  # aes, chacha20
  key_provider: "file"  # file, vault, kms
```

### Key Configuration
```yaml
keys:
  encryption_key:
    path: "/etc/ssh-dashboard/keys/encryption.key"
    permissions: "600"
    rotation: 90  # days
  
  signing_key:
    path: "/etc/ssh-dashboard/keys/signing.key"
    permissions: "600"
    rotation: 180  # days
```

## Data at Rest

### File Encryption
```yaml
file_encryption:
  enabled: true
  algorithm: "aes-256-gcm"
  key_derivation: "pbkdf2"
  
  paths:
    - path: "/etc/ssh-dashboard/secrets"
      type: "directory"
    - path: "/var/log/ssh-dashboard"
      type: "directory"
```

### Database Encryption
```yaml
database:
  encryption:
    enabled: true
    columns:
      - table: "users"
        columns: ["password", "api_key"]
      - table: "sessions"
        columns: ["token"]
```

### Credential Encryption
```yaml
credentials:
  encryption:
    enabled: true
    provider: "vault"
    
    vault:
      address: "https://vault.example.com"
      token: "your-token"
      path: "secret/ssh-dashboard"
```

## Data in Transit

### TLS Configuration
```yaml
tls:
  enabled: true
  cert_file: "/etc/ssl/certs/dashboard.crt"
  key_file: "/etc/ssl/private/dashboard.key"
  
  protocols:
    - "TLSv1.2"
    - "TLSv1.3"
  
  ciphers:
    - "ECDHE-ECDSA-AES256-GCM-SHA384"
    - "ECDHE-RSA-AES256-GCM-SHA384"
```

### API Encryption
```yaml
api:
  encryption:
    enabled: true
    method: "tls"
    mutual_tls: true
    
    client_ca: "/etc/ssl/ca.crt"
    verify_client: true
```

### SSH Encryption
```yaml
ssh:
  encryption:
    ciphers:
      - "chacha20-poly1305@openssh.com"
      - "aes256-gcm@openssh.com"
    
    kex:
      - "curve25519-sha256"
      - "diffie-hellman-group14-sha256"
    
    macs:
      - "hmac-sha2-512-etm@openssh.com"
      - "hmac-sha2-256-etm@openssh.com"
```

## Key Management

### Key Generation
```yaml
key_generation:
  type: "rsa"  # rsa, ed25519
  size: 4096
  passphrase: true
```

### Key Storage
```yaml
key_storage:
  provider: "vault"
  
  vault:
    address: "https://vault.example.com"
    token: "your-token"
    path: "secret/ssh-dashboard/keys"
```

### Key Rotation
```yaml
key_rotation:
  enabled: true
  schedule: "0 0 1 * *"  # monthly
  backup: true
  notify: true
```

## Cloud Key Management

### AWS KMS
```yaml
aws_kms:
  enabled: true
  region: "us-west-2"
  key_id: "your-key-id"
  
  credentials:
    access_key: "your-access-key"
    secret_key: "your-secret-key"
```

### Google Cloud KMS
```yaml
google_kms:
  enabled: true
  project: "your-project"
  location: "global"
  key_ring: "ssh-dashboard"
  key_name: "encryption-key"
```

## Hardware Security Module

### HSM Configuration
```yaml
hsm:
  enabled: true
  provider: "softhsm2"  # softhsm2, luna
  slot: 0
  pin: "your-pin"
  
  keys:
    - label: "encryption"
      type: "aes"
      size: 256
    - label: "signing"
      type: "rsa"
      size: 2048
```

## Monitoring

### Encryption Status
```yaml
monitoring:
  encryption:
    enabled: true
    metrics:
      - "key_age"
      - "encryption_operations"
      - "decryption_operations"
```

### Key Health
```yaml
key_health:
  check_interval: 3600
  alerts:
    - condition: "key_age > 90d"
      severity: "warning"
    - condition: "key_compromised"
      severity: "critical"
```

## Backup and Recovery

### Key Backup
```yaml
key_backup:
  enabled: true
  location: "/backup/keys"
  encryption: true
  schedule: "0 0 * * 0"  # weekly
```

### Recovery Procedure
```yaml
recovery:
  keys:
    backup_location: "/backup/keys"
    verification: true
    notify_admins: true
```

## Best Practices

1. **Key Management**
   - Secure generation
   - Regular rotation
   - Access control
   - Backup strategy

2. **Algorithm Selection**
   - Strong algorithms
   - Future-proof choices
   - Regular updates
   - Compliance

3. **Operational Security**
   - Monitoring
   - Audit logging
   - Incident response
   - Documentation

## Related Documentation

- [Security Configuration](security_configuration.md)
- [Authentication Guide](authentication.md)
- [Key Management](key_management.md)
- [Compliance Guide](compliance.md)

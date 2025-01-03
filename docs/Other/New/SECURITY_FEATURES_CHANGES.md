# Security Features Changes Required

## 1. Key Rotation

### Current State
```bash
# No automatic key rotation
# Keys are manually managed
# No key expiration tracking
```

### Required Changes
```bash
# Add to lib/key_manager.sh
#!/bin/bash

KEY_STORE="/etc/monitor/keys"
KEY_METADATA="$KEY_STORE/metadata.json"
ROTATION_INTERVAL=90  # days

initialize_key_store() {
    mkdir -p "$KEY_STORE"
    chmod 700 "$KEY_STORE"
    
    if [ ! -f "$KEY_METADATA" ]; then
        echo '{
            "keys": [],
            "last_rotation": null,
            "next_rotation": null
        }' > "$KEY_METADATA"
        chmod 600 "$KEY_METADATA"
    fi
}

rotate_keys() {
    local key_type="ed25519"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local new_key="$KEY_STORE/id_${key_type}_${timestamp}"
    
    # Generate new key pair
    ssh-keygen -t "$key_type" -f "$new_key" -N "" -C "monitor_${timestamp}"
    
    # Update authorized keys on remote hosts
    update_remote_keys "$new_key.pub"
    
    # Update metadata
    local next_rotation=$(date -d "+${ROTATION_INTERVAL} days" +%Y-%m-%d)
    update_key_metadata "$new_key" "$next_rotation"
    
    # Archive old keys
    archive_old_keys
}

update_remote_keys() {
    local new_key="$1"
    local hosts_file="$KEY_STORE/hosts.txt"
    
    while IFS=: read -r host user; do
        ssh-copy-id -i "$new_key" "${user}@${host}"
    done < "$hosts_file"
}

archive_old_keys() {
    local archive_dir="$KEY_STORE/archive"
    mkdir -p "$archive_dir"
    
    find "$KEY_STORE" -name "id_*" -mtime +${ROTATION_INTERVAL} -exec mv {} "$archive_dir/" \;
}
```

## 2. Session Management

### Current State
```bash
# Basic SSH session handling
# No session tracking
# No timeout management
```

### Required Changes
```bash
# Add to lib/session_manager.sh
#!/bin/bash

SESSION_DIR="/var/run/monitor/sessions"
SESSION_TIMEOUT=3600  # 1 hour

initialize_session_manager() {
    mkdir -p "$SESSION_DIR"
    chmod 700 "$SESSION_DIR"
}

create_session() {
    local user="$1"
    local host="$2"
    local session_id=$(uuidgen)
    local session_file="$SESSION_DIR/${session_id}"
    
    echo "{
        \"id\": \"${session_id}\",
        \"user\": \"${user}\",
        \"host\": \"${host}\",
        \"created\": \"$(date -Iseconds)\",
        \"expires\": \"$(date -d "+1 hour" -Iseconds)\",
        \"active\": true
    }" > "$session_file"
    
    chmod 600 "$session_file"
    echo "$session_id"
}

validate_session() {
    local session_id="$1"
    local session_file="$SESSION_DIR/${session_id}"
    
    if [ ! -f "$session_file" ]; then
        return 1
    fi
    
    local expires=$(jq -r .expires "$session_file")
    if [[ $(date +%s) -gt $(date -d "$expires" +%s) ]]; then
        invalidate_session "$session_id"
        return 1
    fi
    
    return 0
}

extend_session() {
    local session_id="$1"
    local session_file="$SESSION_DIR/${session_id}"
    
    if validate_session "$session_id"; then
        local new_expires=$(date -d "+1 hour" -Iseconds)
        jq --arg expires "$new_expires" '.expires = $expires' "$session_file" > "${session_file}.tmp"
        mv "${session_file}.tmp" "$session_file"
        return 0
    fi
    return 1
}

cleanup_sessions() {
    find "$SESSION_DIR" -type f -mmin +60 -delete
}
```

## 3. Access Control

### Current State
```bash
# No role-based access
# Basic user permissions
# No access logging
```

### Required Changes
```bash
# Add to lib/access_control.sh
#!/bin/bash

ACL_DIR="/etc/monitor/acl"
ACL_FILE="$ACL_DIR/access_control.yaml"
ACCESS_LOG="$ACL_DIR/access.log"

initialize_acl() {
    mkdir -p "$ACL_DIR"
    chmod 700 "$ACL_DIR"
    
    if [ ! -f "$ACL_FILE" ]; then
        echo "roles:
  admin:
    permissions: ['*']
  operator:
    permissions:
      - 'monitor:read'
      - 'monitor:write'
      - 'system:read'
  viewer:
    permissions:
      - 'monitor:read'
      - 'system:read'

users:
  admin:
    role: admin
    hosts: ['*']
  operator:
    role: operator
    hosts: ['192.168.1.*']" > "$ACL_FILE"
    fi
}

check_permission() {
    local user="$1"
    local permission="$2"
    local host="$3"
    
    # Load user role
    local role=$(yq -r ".users.${user}.role" "$ACL_FILE")
    if [ "$role" = "null" ]; then
        log_access "DENY" "$user" "$permission" "$host" "User not found"
        return 1
    fi
    
    # Check permission
    if yq -r ".roles.${role}.permissions[] | select(. == \"${permission}\" or . == \"*\")" "$ACL_FILE" | grep -q .; then
        # Check host access
        local allowed_hosts=$(yq -r ".users.${user}.hosts[]" "$ACL_FILE")
        if echo "$allowed_hosts" | grep -q "\*\|$host"; then
            log_access "ALLOW" "$user" "$permission" "$host"
            return 0
        fi
    fi
    
    log_access "DENY" "$user" "$permission" "$host" "Permission denied"
    return 1
}

log_access() {
    local action="$1"
    local user="$2"
    local permission="$3"
    local host="$4"
    local reason="${5:-}"
    
    echo "$(date -Iseconds)|${action}|${user}|${permission}|${host}|${reason}" >> "$ACCESS_LOG"
}
```

## 4. Encryption

### Current State
```bash
# No data encryption
# Plain text configurations
# Unencrypted logs
```

### Required Changes
```bash
# Add to lib/encryption_manager.sh
#!/bin/bash

KEYRING_DIR="/etc/monitor/keyring"
MASTER_KEY_FILE="$KEYRING_DIR/master.key"
KEY_CACHE="/dev/shm/monitor_keys"

initialize_encryption() {
    mkdir -p "$KEYRING_DIR"
    chmod 700 "$KEYRING_DIR"
    
    if [ ! -f "$MASTER_KEY_FILE" ]; then
        openssl rand -base64 32 > "$MASTER_KEY_FILE"
        chmod 400 "$MASTER_KEY_FILE"
    fi
    
    # Set up secure memory for key cache
    mkdir -p "$KEY_CACHE"
    chmod 700 "$KEY_CACHE"
    mount -t tmpfs -o size=1M,mode=700 tmpfs "$KEY_CACHE"
}

encrypt_file() {
    local input_file="$1"
    local output_file="${2:-${input_file}.enc}"
    
    openssl enc -aes-256-cbc -salt -in "$input_file" \
            -out "$output_file" -pass file:"$MASTER_KEY_FILE"
    
    chmod 600 "$output_file"
}

decrypt_file() {
    local input_file="$1"
    local output_file="${2:-${input_file%.enc}}"
    
    openssl enc -d -aes-256-cbc -in "$input_file" \
            -out "$output_file" -pass file:"$MASTER_KEY_FILE"
}

secure_delete() {
    local file="$1"
    shred -u "$file"
}

cleanup_keys() {
    # Securely unmount and clean key cache
    umount "$KEY_CACHE"
    rm -rf "$KEY_CACHE"
}
```

## Implementation Strategy

1. Phase 1: Key Management
   - Implement key rotation
   - Add key metadata tracking
   - Create key archive system

2. Phase 2: Session Control
   - Add session tracking
   - Implement timeouts
   - Create cleanup routines

3. Phase 3: Access Control
   - Implement ACL system
   - Add role management
   - Create access logging

4. Phase 4: Encryption
   - Add file encryption
   - Implement secure storage
   - Create key management

## Testing Requirements

1. Key Management Tests
   - Key generation
   - Rotation scheduling
   - Remote key updates

2. Session Tests
   - Creation/validation
   - Timeout handling
   - Cleanup processes

3. Access Control Tests
   - Permission checks
   - Role inheritance
   - Host restrictions

4. Encryption Tests
   - File encryption
   - Key handling
   - Secure deletion

## Security Considerations

1. Key Storage
   - Secure key storage
   - Regular rotation
   - Access monitoring

2. Session Security
   - Timeout enforcement
   - Session validation
   - Cleanup procedures

3. Access Management
   - Least privilege
   - Role separation
   - Audit logging

4. Data Protection
   - Encryption at rest
   - Secure memory handling
   - Safe key disposal

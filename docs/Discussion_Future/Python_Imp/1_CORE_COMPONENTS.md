# Core Components Design

## Platform-Independent Core

### 1. Environment Manager
```python
class EnvironmentManager:
    def __init__(self):
        self.platform = self.detect_platform()
        self.paths = self.init_paths()
        self.config = self.load_config()

    def detect_platform(self):
        # Returns: 'windows', 'wsl', 'linux'
        # Handles platform-specific initialization
        pass

    def init_paths(self):
        # Platform-specific paths
        return {
            'config': self.get_config_path(),
            'logs': self.get_logs_path(),
            'locks': self.get_locks_path(),
            'data': self.get_data_path()
        }

    def get_config_path(self):
        # Windows: %APPDATA%/ssh_monitor/config
        # Linux/WSL: ~/.ssh_monitor/config
        pass
```

### 2. Process Manager
```python
class ProcessManager:
    def __init__(self, env_manager):
        self.env = env_manager
        self.lock_file = self.env.paths['locks'] / 'service.lock'
        self.pid_file = self.env.paths['locks'] / 'service.pid'

    def acquire_lock(self):
        # Cross-platform file locking
        # Returns lock object or None
        pass

    def release_lock(self):
        # Safe lock release
        pass

    def is_running(self):
        # Check if service is running
        # Verify PID file and process existence
        pass
```

### 3. Configuration Manager
```python
class ConfigManager:
    def __init__(self, env_manager):
        self.env = env_manager
        self.config = self.load_config()
        self.validate_config()

    def load_config(self):
        # Load .conf files (not YAML)
        # Platform-specific paths
        pass

    def get_ssh_config(self):
        # SSH-specific settings
        pass

    def get_monitor_config(self):
        # Monitoring settings
        pass
```

## Implementation Steps

1. Environment Setup
```bash
# Windows (PowerShell)
./setup.ps1
  ├── Check prerequisites
  ├── Create directory structure
  └── Initialize config files

# Linux/WSL
./setup.sh
  ├── Check prerequisites
  ├── Create directory structure
  └── Initialize config files
```

2. Configuration Files
```ini
# ssh_monitor.conf
[paths]
config_dir=%APPDATA%/ssh_monitor/config
logs_dir=%APPDATA%/ssh_monitor/logs
data_dir=%APPDATA%/ssh_monitor/data

[ssh]
key_type=ed25519
key_bits=4096
timeout=30

[monitor]
interval=60
max_retries=3
```

3. Directory Structure
```
ssh_monitor/
├── config/
│   ├── ssh_monitor.conf
│   ├── ssh_config
│   └── known_hosts
├── logs/
│   ├── service.log
│   └── error.log
├── data/
│   ├── state.db
│   └── metrics.db
└── locks/
    ├── service.lock
    └── service.pid
```

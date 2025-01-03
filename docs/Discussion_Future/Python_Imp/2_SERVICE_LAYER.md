# Service Layer Design

## Service Components

### 1. Service Controller
```python
class ServiceController:
    def __init__(self, env_manager):
        self.env = env_manager
        self.process_mgr = ProcessManager(env_manager)
        self.config_mgr = ConfigManager(env_manager)
        self.logger = Logger(env_manager)

    def start(self):
        # 1. Check if already running
        # 2. Acquire lock
        # 3. Start monitor threads
        # 4. Write PID file
        pass

    def stop(self):
        # 1. Signal threads to stop
        # 2. Wait for completion
        # 3. Release lock
        # 4. Remove PID file
        pass

    def status(self):
        # Return service status
        # Include thread states
        pass
```

### 2. Monitor Thread Manager
```python
class MonitorThreadManager:
    def __init__(self, service_controller):
        self.controller = service_controller
        self.threads = []
        self.stop_event = threading.Event()

    def start_monitors(self):
        # Start monitor threads:
        # - SSH Monitor
        # - System Monitor
        # - Reboot Monitor
        pass

    def stop_monitors(self):
        # Signal and wait for threads
        pass

    def check_threads(self):
        # Monitor thread health
        # Restart if needed
        pass
```

### 3. Data Manager
```python
class DataManager:
    def __init__(self, env_manager):
        self.env = env_manager
        self.db_path = self.env.paths['data'] / 'state.db'
        self.metrics_path = self.env.paths['data'] / 'metrics.db'

    def save_state(self, state_data):
        # Save current state
        # Handle file locking
        pass

    def load_state(self):
        # Load last known state
        # Handle missing data
        pass

    def save_metrics(self, metrics_data):
        # Save monitoring metrics
        # Handle rotation
        pass
```

## Implementation Steps

1. Service Control Scripts
```bash
# Windows (PowerShell)
./service.ps1
  ├── start   # Start service
  ├── stop    # Stop service
  ├── status  # Check status
  └── restart # Restart service

# Linux/WSL
./service.sh
  ├── start   # Start service
  ├── stop    # Stop service
  ├── status  # Check status
  └── restart # Restart service
```

2. State Management
```sql
-- state.db schema
CREATE TABLE service_state (
    id INTEGER PRIMARY KEY,
    timestamp TEXT,
    status TEXT,
    last_check TEXT,
    error TEXT
);

-- metrics.db schema
CREATE TABLE metrics (
    id INTEGER PRIMARY KEY,
    timestamp TEXT,
    metric_type TEXT,
    value TEXT
);
```

3. Error Recovery
```python
def recover_from_error(error_type):
    if error_type == 'lock_error':
        # Clean stale locks
        pass
    elif error_type == 'thread_error':
        # Restart thread
        pass
    elif error_type == 'connection_error':
        # Reconnect SSH
        pass
```

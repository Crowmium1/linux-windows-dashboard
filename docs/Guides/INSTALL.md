# Installation Guide

## Windows Setup

1. Install Windows OpenSSH:
   - Open Windows Settings
   - Go to Apps > Optional Features
   - Click "Add a feature"
   - Install both "OpenSSH Client" and "OpenSSH Server"

2. Install Git Bash:
   - Download from https://git-scm.com/download/win
   - During installation, select "Use Git and optional Unix tools from the Windows Command Prompt"

3. Install Required Tools in Git Bash:
   ```bash
   # Update package list
   pacman -Syu

   # Install essential tools
   pacman -S openssh rsync inotify-tools cd net-tools

   # Verify SSH installation
   ssh -V
   ```

## Testing Setup

1. Create test directories:
   ```bash
   ./scripts/setup_project.sh
   ```

2. Set up SSH key (if not using password authentication):
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

3. Run the tests:
   ```bash
   cd tests
   ./test_ssh_recovery_tools.sh
   ```

## Troubleshooting

### SSH Connection Issues
- Ensure SSH service is running:
  ```bash
  # Check SSH service status
  sc query sshd
  # Start SSH service if needed
  net start sshd
  ```

- Check SSH configuration:
  ```bash
  # Test SSH connection
  ssh -v localhost
  ```

### Permission Issues
- Ensure scripts are executable:
  ```bash
  chmod +x scripts/*.sh
  chmod +x tests/*.sh
  ```

- Check file permissions:
  ```bash
  ls -la scripts/
  ls -la tests/
  ```

### Path Issues
- Ensure Git Bash is in your PATH
- Verify tool locations:
  ```bash
  which ssh
  which rsync
  ```

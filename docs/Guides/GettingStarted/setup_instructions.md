# SSH Setup Instructions

This document outlines the steps needed to set up your SSH environment after a system restart or when moving to a new project.

## Initial Setup (Main Machine - WSL)

1. Start WSL and navigate to the project directory
```bash
cd /path/to/keyring/core
```

2. Run the environment setup script first:
```bash
./setup_environment.sh
```

3. After the environment script completes:
   - Close the terminal
   - Open a new WSL terminal
   - Verify the environment is set up:
```bash
env | grep -E "DBUS|SSH|GNOME"
```

## SSH Setup (Main Machine - WSL)

1. Now run the passwordless SSH setup script:
```bash
./setup_passwordless_ssh.sh
```

2. If prompted for a passphrase, enter it.

3. Verify the SSH agent is running:
```bash
ssh-add -l
```

## Remote Machine Setup

1. Check SSH service status:
```bash
sudo systemctl status sshd
```

2. If not running, start the SSH service:
```bash
sudo systemctl start sshd
```

## Testing the Connection

1. Test SSH connection (replace with your configured host from ~/.ssh/config):
```bash
ssh ubuntu-remote
```

2. If you get port errors:
   - Verify the port settings in `/etc/ssh/sshd_config` on the remote machine
   - Check your SSH config file (`~/.ssh/config`) on the main machine

## Troubleshooting

If you encounter issues:

1. Check SSH agent:
```bash
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519
```

2. Verify permissions:
```bash
ls -la ~/.ssh/
```
- Directory (`~/.ssh/`) should be 700
- Public key (`.pub`) should be 644
- Private key should be 600
- config file should be 600

3. Check SSH verbose output for detailed errors:
```bash
ssh -vv ubuntu-remote
```

## Note

- You'll need to run these setup steps after each system restart
- The SSH key passphrase needs to be entered once per session
- After initial setup, subsequent SSH connections should work without password prompts

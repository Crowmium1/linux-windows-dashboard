#!/bin/bash

# Script directory and config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/dashboard_config.conf"

# Add shellcheck directive for sourced file
# shellcheck source=/dev/null
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local message=$1
    local status=$2
    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓ $message${NC}"
    else
        echo -e "${RED}✗ $message${NC}"
    fi
    return $status
}

# Function to show menu
show_menu() {
    clear
    echo -e "${BLUE}=== SSH Setup Manager ===${NC}"
    echo "1) Setup SSH Environment"
    echo "2) Setup Passwordless SSH"
    echo "3) Run SSH Diagnostics"
    echo "4) Test SSH Connection"
    echo "5) Logout of SSH"
    echo "q) Quit"
    echo
    echo -e "${YELLOW}Recommended workflow:${NC}"
    echo "1. Run Environment Setup (1)"
    echo "2. Run Passwordless Setup (2)"
    echo "3. Verify with Diagnostics (3)"
    echo "4. Test Connection (4)"
    echo "5. Logout when done (5)"
    echo
}

# Function to check login status
check_login_status() {
    if [ -z "$SSH_AGENT_PID" ] || ! ps -p "$SSH_AGENT_PID" >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Function to setup SSH directory
setup_ssh_dir() {
    echo "Setting up SSH directory..."
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Create authorized_keys if it doesn't exist
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    
    local status=$?
    print_status "SSH directory setup" $status
    return $status
}

# Function to setup SSH agent
setup_ssh_agent() {
    echo "Setting up SSH agent..."
    
    # Start SSH agent if not running
    if [ -z "$SSH_AGENT_PID" ] || ! ps -p "$SSH_AGENT_PID" >/dev/null 2>&1; then
        eval "$(ssh-agent -s)"
    fi
    
    # Add the key to the agent
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
    fi
    
    # Add automatic agent startup to bashrc if not already present
    if ! grep -q "Start SSH agent automatically" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOL'

# Start SSH agent automatically
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
EOL
    fi
    
    local status=$?
    print_status "SSH agent setup" $status
    return $status
}

# Function to check SSH server prerequisites
check_prerequisites() {
    if grep -qi microsoft /proc/version; then
        # Running in WSL
        if [ "${TEST_MODE:-0}" = "1" ]; then
            echo "Test mode: Skipping Windows prerequisite checks"
            return 0
        fi
        check_windows_prerequisites
    else
        # Running in native Linux
        if [ "${TEST_MODE:-0}" = "1" ]; then
            echo "Test mode: Skipping Linux prerequisite checks"
            return 0
        fi
        check_linux_prerequisites
    fi
}

# Function to check Linux prerequisites
check_linux_prerequisites() {
    # Check if openssh-server is installed
    if ! command -v sshd >/dev/null 2>&1; then
        echo -e "${RED}✗ OpenSSH server is not installed${NC}"
        echo "For Debian/Ubuntu:"
        echo "  sudo apt update && sudo apt install openssh-server"
        echo "For RHEL/CentOS:"
        echo "  sudo dnf install openssh-server"
        return 1
    fi
    echo -e "${GREEN}✓ OpenSSH server is installed${NC}"
    
    # Check if SSH service is running
    local service_name="ssh"  # Default for Debian/Ubuntu
    if [ -f "/etc/redhat-release" ]; then
        service_name="sshd"   # For RHEL/CentOS
    fi
    
    if command -v systemd >/dev/null 2>&1; then
        if ! systemctl is-active --quiet "$service_name"; then
            echo -e "${RED}✗ SSH service is not running${NC}"
            echo "Please run:"
            echo "  sudo systemctl start $service_name"
            echo "  sudo systemctl enable $service_name"
            echo
            echo "To stop the service:"
            echo "  sudo systemctl stop $service_name"
            echo "To disable auto-start:"
            echo "  sudo systemctl disable $service_name"
            return 1
        fi
    else
        if ! service "$service_name" status >/dev/null 2>&1; then
            echo -e "${RED}✗ SSH service is not running${NC}"
            echo "Please run:"
            echo "  sudo service $service_name start"
            echo "  sudo chkconfig $service_name on"
            return 1
        fi
    fi
    echo -e "${GREEN}✓ SSH service is running${NC}"
    
    # Check firewall
    if command -v ufw >/dev/null 2>&1; then
        if ! ufw status | grep -q "22/tcp.*ALLOW"; then
            echo -e "${YELLOW}! SSH port might not be open in firewall${NC}"
            echo "Please run: sudo ufw allow ssh"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if ! firewall-cmd --list-services | grep -q ssh; then
            echo -e "${YELLOW}! SSH port might not be open in firewall${NC}"
            echo "Please run:"
            echo "  sudo firewall-cmd --permanent --add-service=ssh"
            echo "  sudo firewall-cmd --reload"
        fi
    fi
    
    # Check home directory permissions
    if [ "$(stat -c %a ~)" != "755" ] && [ "$(stat -c %a ~)" != "750" ]; then
        echo -e "${YELLOW}! Home directory permissions should be 755 or 750${NC}"
        echo "Please run: chmod 755 ~"
        return 1
    fi
    echo -e "${GREEN}✓ Home directory permissions are correct${NC}"
    
    # Check .ssh directory
    if [ ! -d ~/.ssh ]; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
    elif [ "$(stat -c %a ~/.ssh)" != "700" ]; then
        chmod 700 ~/.ssh
    fi
    echo -e "${GREEN}✓ SSH directory permissions are correct${NC}"
    
    return 0
}

# Function to check Windows prerequisites
check_windows_prerequisites() {
    local status=0
    
    # Check if Windows OpenSSH is installed
    if [ -f "/mnt/c/Windows/System32/OpenSSH/ssh.exe" ]; then
        echo -e "${GREEN}✓ Windows OpenSSH client found${NC}"
    else
        echo -e "${RED}✗ Windows OpenSSH client not found${NC}"
        echo "Please install OpenSSH in Windows:"
        echo "1. Open PowerShell as Administrator"
        echo "2. Run: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
        status=1
    fi
    
    # Check if Windows OpenSSH server is installed (optional)
    if [ -f "/mnt/c/Windows/System32/OpenSSH/sshd.exe" ]; then
        echo -e "${GREEN}✓ Windows OpenSSH server found${NC}"
    else
        echo -e "${YELLOW}! Windows OpenSSH server not found (optional)${NC}"
        echo "To install OpenSSH server in Windows:"
        echo "1. Open PowerShell as Administrator"
        echo "2. Run: Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
    fi
    
    # Check WSL SSH (fallback)
    if command -v ssh >/dev/null; then
        echo -e "${GREEN}✓ WSL SSH client found${NC}"
    else
        echo -e "${RED}✗ WSL SSH client not found${NC}"
        echo "Please install OpenSSH in WSL:"
        echo "sudo apt-get update && sudo apt-get install -y openssh-client"
        status=1
    fi
    
    return $status
}

# Function to run environment setup
run_env_setup() {
    echo -e "\n${BLUE}=== Setting up SSH Environment ===${NC}"
    
    # Check prerequisites first
    check_prerequisites
    local prereq_status=$?
    if [ $prereq_status -ne 0 ]; then
        echo -e "\n${RED}✗ Prerequisites check failed${NC}"
        echo "Please fix the issues above before continuing"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Setup SSH directory
    setup_ssh_dir
    local dir_status=$?
    
    # Setup SSH agent
    setup_ssh_agent
    local agent_status=$?
    
    if [ $dir_status -eq 0 ] && [ $agent_status -eq 0 ]; then
        echo -e "\n${GREEN}✓ Environment setup completed successfully${NC}"
    else
        echo -e "\n${RED}✗ Environment setup encountered issues${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to run passwordless setup
run_passwordless_setup() {
    echo -e "\n${BLUE}=== Setting up Passwordless SSH ===${NC}"
    
    # Check if logged in
    if ! check_login_status; then
        echo -e "${RED}You are not logged in${NC}"
        echo "Please run the environment setup first"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    local key_file="$HOME/.ssh/id_ed25519"
    
    # Generate key if it doesn't exist
    if [ ! -f "$key_file" ]; then
        echo "Generating new SSH key..."
        ssh-keygen -t ed25519 -f "$key_file" -N "" -C "dashboard_monitor_$(date +%Y%m%d)"
        chmod 600 "$key_file"
        chmod 644 "${key_file}.pub"
        print_status "SSH key generation" $?
    else
        echo -e "${YELLOW}! SSH key already exists${NC}"
    fi
    
    # Create authorized_keys if it doesn't exist
    if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
        touch "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
    fi
    
    # Add key to authorized_keys if not already there
    if ! grep -qf "${key_file}.pub" "$HOME/.ssh/authorized_keys"; then
        cat "${key_file}.pub" >> "$HOME/.ssh/authorized_keys"
        print_status "Adding key to authorized_keys" $?
    fi
    
    # Add key to agent
    ssh-add "$key_file" 2>/dev/null
    print_status "Adding key to agent" $?
    
    # Copy key to remote system
    echo "Copying SSH key to remote system..."
    if ! ping -c 1 localhost >/dev/null 2>&1; then
        echo -e "${RED}✗ Cannot reach localhost${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    if ssh-copy-id -i "${key_file}.pub" "$USER@localhost" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ SSH key copied successfully${NC}"
    else
        echo -e "${RED}✗ Failed to copy SSH key${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to run diagnostics
run_diagnostics() {
    echo -e "\n${BLUE}=== Running SSH Diagnostics ===${NC}"
    
    # Check SSH agent
    if [ -n "$SSH_AGENT_PID" ] && ps -p "$SSH_AGENT_PID" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ SSH agent is running (PID: $SSH_AGENT_PID)${NC}"
    else
        echo -e "${RED}✗ SSH agent is not running${NC}"
    fi
    
    # Check SSH key
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        echo -e "${GREEN}✓ SSH key exists${NC}"
        if ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf ~/.ssh/id_ed25519 | awk '{print $2}')"; then
            echo -e "${GREEN}✓ Key is loaded in agent${NC}"
        else
            echo -e "${YELLOW}! Key is not loaded in agent${NC}"
        fi
    else
        echo -e "${RED}✗ SSH key does not exist${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Function to test connection
test_connection() {
    echo -e "\n${BLUE}=== Testing SSH Connection ===${NC}"
    
    echo "Testing connection to $USER@localhost..."
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$USER@localhost" "echo 'Connection successful'" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ SSH connection successful${NC}"
    else
        echo -e "${RED}✗ SSH connection failed${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Parse command line arguments
parse_args() {
    TEST_MODE=0
    NONINTERACTIVE=0
    HOST=""
    USER=""
    PORT="22"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --test-mode)
                TEST_MODE=1
                NONINTERACTIVE=1
                shift
                ;;
            --host=*)
                HOST="${1#*=}"
                shift
                ;;
            --user=*)
                USER="${1#*=}"
                shift
                ;;
            --port=*)
                PORT="${1#*=}"
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"
    
    if [ $NONINTERACTIVE -eq 1 ]; then
        # Non-interactive mode for testing
        if [ -z "$HOST" ] || [ -z "$USER" ]; then
            echo "Error: Host and user required in non-interactive mode"
            echo "Usage: $0 --test-mode --host=hostname --user=username [--port=22]"
            exit 1
        fi
        
        # Run setup steps without interaction
        check_prerequisites || exit 1
        setup_ssh_dir || exit 1
        setup_ssh_agent || exit 1
        
        # Run passwordless setup with provided credentials
        REMOTE_HOST="$HOST"
        REMOTE_USER="$USER"
        REMOTE_PORT="$PORT"
        run_passwordless_setup || exit 1
        
        echo "SSH setup completed successfully"
        exit 0
    fi
    
    # Interactive menu mode
    while true; do
        show_menu
        read -p "Choose an option: " choice
        case $choice in
            1) run_env_setup ;;
            2) run_passwordless_setup ;;
            3) run_diagnostics ;;
            4) test_connection ;;
            5) ssh-add -D && echo "SSH keys removed" ;;
            q|Q) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
        echo
        read -p "Press Enter to continue..."
    done
}

main "$@"

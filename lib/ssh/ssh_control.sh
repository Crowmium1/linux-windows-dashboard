#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# SSH connection details
SSH_USER="lj"
SSH_HOST="192.168.17.193"

# Function to check SSH connection
check_ssh() {
    ssh -q -o BatchMode=yes -o ConnectTimeout=5 ${SSH_USER}@${SSH_HOST} exit
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSH connection successful${NC}"
        return 0
    else
        echo -e "${RED}SSH connection failed${NC}"
        return 1
    fi
}

# Function to run remote command
run_remote() {
    ssh ${SSH_USER}@${SSH_HOST} "$1"
}

# Function to copy file to remote
copy_to_remote() {
    scp "$1" ${SSH_USER}@${SSH_HOST}:"$2"
}

# Main menu
show_menu() {
    clear
    echo -e "${YELLOW}=== SSH Control Center ===${NC}"
    echo "1) System Monitoring"
    echo "2) System Configuration"
    echo "3) Firmware Management"
    echo "4) Graphics Configuration"
    echo "5) Error Resolution"
    echo "6) Service Management"
    echo "7) Copy Toolkit to Remote"
    echo "8) Exit"
    
    read -p "Select an option: " choice
    
    case $choice in
        1)
            cd monitoring
            ./collect_system_info.sh
            ;;
        2)
            cd system
            echo -e "${YELLOW}Available configuration scripts:${NC}"
            ls -1 configure_*.sh
            read -p "Enter script name to run: " script
            ./$script
            ;;
        3)
            cd firmware
            ./firmware_manager.sh
            ;;
        4)
            cd monitoring
            ./graphics_check.sh
            ;;
        5)
            cd errors
            ./error_resolver.sh
            ;;
        6)
            cd monitoring
            ./service_check.sh
            ;;
        7)
            echo -e "${YELLOW}Copying toolkit to remote system...${NC}"
            tar czf toolkit.tar.gz *
            copy_to_remote "toolkit.tar.gz" "~/ssh_toolkit.tar.gz"
            run_remote "cd ~ && tar xzf ssh_toolkit.tar.gz && chmod +x ssh_toolkit/**/*.sh"
            echo -e "${GREEN}Toolkit copied and extracted${NC}"
            ;;
        8)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

# Check SSH before starting
if check_ssh; then
    while true; do
        show_menu
        read -p "Press Enter to continue..."
    done
else
    echo -e "${RED}Cannot establish SSH connection${NC}"
    exit 1
fi

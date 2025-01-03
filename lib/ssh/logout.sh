#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Logging out of SSH ===${NC}"

# Check if anyone is logged in
logged_in_users=$(who | grep -v "$(whoami)" | wc -l)
if [ "$logged_in_users" -gt 0 ]; then
    echo -e "${RED}Warning: Other users are still logged in${NC}"
    who | grep -v "$(whoami)"
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Logout cancelled"
        exit 1
    fi
fi

# Stop SSH agent
echo "Stopping SSH agent..."
if [ -n "$SSH_AGENT_PID" ]; then
    kill $SSH_AGENT_PID 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSH agent stopped${NC}"
    else
        echo -e "${RED}✗ Failed to stop SSH agent${NC}"
    fi
else
    echo -e "${YELLOW}! No SSH agent running${NC}"
fi

# Backup authorized_keys
echo "Backing up authorized_keys..."
if [ -f ~/.ssh/authorized_keys ]; then
    cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.backup
    echo -e "${GREEN}✓ authorized_keys backed up to authorized_keys.backup${NC}"
else
    echo -e "${YELLOW}! No authorized_keys file found${NC}"
fi

# Clean environment variables
echo "Cleaning environment variables..."
unset SSH_AGENT_PID
unset SSH_AUTH_SOCK

# Final cleanup
echo "Ensuring all SSH processes are terminated..."
killall -u $USER ssh-agent 2>/dev/null
killall -u $USER ssh 2>/dev/null

echo -e "\n${GREEN}Logout complete${NC}"

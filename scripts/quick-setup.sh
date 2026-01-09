#!/bin/bash
#
# Quick Setup Script for Ubuntu Server Security
# This script helps you quickly deploy the Ansible playbooks
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ubuntu Server Security - Quick Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${YELLOW}Ansible is not installed. Installing...${NC}"
    sudo apt update
    sudo apt install -y ansible
fi

echo -e "${GREEN}✓ Ansible installed${NC}"

# Check if inventory file exists
if [ ! -f "inventory.ini" ]; then
    echo -e "${YELLOW}Creating inventory.ini from example...${NC}"
    cp inventory.ini.example inventory.ini
    echo -e "${YELLOW}Please edit inventory.ini with your server details${NC}"
    echo -e "${YELLOW}Press Enter when ready to continue...${NC}"
    read
fi

# Check if group_vars/all.yml exists
if [ ! -f "group_vars/all.yml" ]; then
    echo -e "${YELLOW}Creating group_vars/all.yml from example...${NC}"
    cp group_vars/all.yml.example group_vars/all.yml
    echo -e "${YELLOW}Please edit group_vars/all.yml with your configuration${NC}"
    echo -e "${YELLOW}Press Enter when ready to continue...${NC}"
    read
fi

echo ""
echo -e "${GREEN}Configuration files ready!${NC}"
echo ""
echo "What would you like to do?"
echo "1. Run full security setup (playbook.yml)"
echo "2. Setup monitoring stack (monitoring.yml)"
echo "3. Create backup (backup-restore.yml)"
echo "4. Test connection to servers"
echo "5. Check playbook syntax"
echo "6. Exit"
echo ""
read -p "Enter choice [1-6]: " choice

case $choice in
    1)
        echo -e "${GREEN}Running full security setup...${NC}"
        ansible-playbook playbook.yml
        ;;
    2)
        echo -e "${GREEN}Setting up monitoring stack...${NC}"
        ansible-playbook monitoring.yml
        ;;
    3)
        echo -e "${GREEN}Creating backup...${NC}"
        ansible-playbook backup-restore.yml
        ;;
    4)
        echo -e "${GREEN}Testing connection...${NC}"
        ansible all -m ping
        ;;
    5)
        echo -e "${GREEN}Checking syntax...${NC}"
        ansible-playbook --syntax-check playbook.yml
        ansible-playbook --syntax-check monitoring.yml
        ansible-playbook --syntax-check backup-restore.yml
        ansible-playbook --syntax-check rollback.yml
        echo -e "${GREEN}✓ All playbooks syntax valid${NC}"
        ;;
    6)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed!${NC}"
echo -e "${GREEN}========================================${NC}"

#!/bin/bash
#
# Repository Structure Creation Script
# Creates the complete Ansible directory structure
#

set -e

echo "Creating Ansible repository structure..."

# Create main directories
mkdir -p group_vars host_vars files/ssh_keys scripts roles

# Create role directories
for role in common users ssh firewall fail2ban cloudflared backup restore prometheus node_exporter grafana alertmanager monitoring_tunnel; do
    mkdir -p "roles/$role"/{tasks,templates,handlers,defaults,files,vars}
    touch "roles/$role/tasks/main.yml"
    touch "roles/$role/handlers/main.yml"
    touch "roles/$role/defaults/main.yml"
    echo "Created role: $role"
done

# Create placeholder files
touch host_vars/.gitkeep
touch files/ssh_keys/.gitkeep

echo ""
echo "✓ Repository structure created successfully!"
echo ""
echo "Next steps:"
echo "1. Copy example configuration files"
echo "2. Update with your server details"
echo "3. Run quick-setup.sh to deploy"

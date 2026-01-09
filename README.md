# Ubuntu Server Security Setup - Ansible Automation

Comprehensive Ansible automation for securing Ubuntu servers with hardening, monitoring, and Cloudflare Tunnel integration. Based on a three-part article series covering best practices for server security.

## Features

### 🔒 Security Hardening
- **System Updates**: Automatic security updates with unattended-upgrades
- **User Management**: Admin and application user creation with SSH key authentication
- **SSH Hardening**: Key-only authentication, root login disabled, connection limits
- **Firewall (UFW)**: Deny all incoming, rate-limited SSH, custom rules support
- **Fail2Ban**: Intrusion prevention with configurable jails
- **Kernel Hardening**: Security-focused kernel parameter tuning

### 🌐 Cloudflare Tunnel
- Zero Trust network access
- No open ports required (after initial setup)
- SSH through Cloudflare Tunnel
- Application exposure with authentication
- Automatic configuration and service setup

### 📊 Monitoring Stack
- **Prometheus**: Metrics collection and alerting
- **Node Exporter**: System metrics (CPU, memory, disk, network)
- **Grafana**: Beautiful dashboards with pre-configured templates
- **Alertmanager**: Email and webhook alert notifications
- **Alert Rules**: CPU, memory, disk, load average, and uptime alerts
- **Secure Access**: Expose via Cloudflare Tunnel with Zero Trust

### 💾 Backup & Restore
- Automated configuration backups
- Configurable retention period (default 30 days)
- Remote storage support (S3, DigitalOcean Spaces)
- One-command restore
- Rollback capabilities for safe experimentation

### 🎯 Operational Excellence
- **Idempotent**: Run multiple times safely
- **Modular**: Use tags to run specific roles
- **Check Mode**: Preview changes before applying
- **Comprehensive Logging**: Audit trail of all changes
- **Rollback Support**: Undo changes if needed

## Quick Start

### Prerequisites

- Ubuntu 20.04 LTS or 22.04 LTS server (freshly installed)
- SSH access with root or sudo privileges
- Ansible 2.10+ on your control machine
- (Optional) Cloudflare account for tunnel setup

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/annurdien/ubuntu-server-setup.git
   cd ubuntu-server-setup
   ```

2. **Install Ansible** (if not already installed)
   ```bash
   sudo apt update
   sudo apt install -y ansible
   ```

3. **Configure your setup**
   ```bash
   # Copy and edit inventory
   cp inventory.ini.example inventory.ini
   vim inventory.ini  # Add your server IPs

   # Copy and edit configuration
   cp group_vars/all.yml.example group_vars/all.yml
   vim group_vars/all.yml  # Update with your settings
   ```

4. **Add your SSH public key**
   ```bash
   # Generate if you don't have one
   ssh-keygen -t ed25519 -C "admin@server"
   
   # Copy public key to files directory
   cp ~/.ssh/id_ed25519.pub files/ssh_keys/admin_id_ed25519.pub
   ```

5. **Run the quick setup script**
   ```bash
   ./scripts/quick-setup.sh
   ```

### Manual Deployment

#### 1. Test Connection
```bash
ansible all -m ping
```

#### 2. Run Full Security Setup
```bash
ansible-playbook playbook.yml
```

#### 3. Setup Monitoring (Optional)
```bash
# Copy monitoring configuration
cp group_vars/monitoring.yml.example group_vars/monitoring.yml
vim group_vars/monitoring.yml  # Update settings

# Run monitoring playbook
ansible-playbook monitoring.yml
```

## Configuration

### Essential Configuration (`group_vars/all.yml`)

```yaml
# Admin user
admin_user:
  name: "admin"
  password: "{{ 'YourSecurePassword' | password_hash('sha512') }}"
  ssh_key: "{{ lookup('file', 'files/ssh_keys/admin_id_ed25519.pub') }}"

# SSH settings
ssh_port: 22
ssh_permit_root_login: "no"
ssh_password_authentication: "no"

# Firewall
ufw_enabled: true
ufw_ssh_rate_limit: true

# Fail2Ban
fail2ban_enabled: true
fail2ban_bantime: 3600
fail2ban_maxretry: 5

# Cloudflare Tunnel (optional)
cloudflare_tunnel_token: "your-token"
domain_name: "example.com"
```

See `group_vars/all.yml.example` for complete configuration options.

## Usage Examples

### Run Specific Roles

```bash
# Only update system packages
ansible-playbook playbook.yml --tags common

# Only configure SSH
ansible-playbook playbook.yml --tags ssh

# Only setup firewall
ansible-playbook playbook.yml --tags firewall

# Setup security (users, SSH, firewall, fail2ban)
ansible-playbook playbook.yml --tags security
```

### Backup and Restore

```bash
# Create backup
ansible-playbook backup-restore.yml
# Select option 1

# Restore from latest backup
ansible-playbook backup-restore.yml
# Select option 2

# List all backups
ansible-playbook backup-restore.yml
# Select option 4
```

### Rollback Changes

```bash
# Interactive rollback
ansible-playbook rollback.yml

# Follow prompts to select what to rollback
```

### Check Mode (Dry Run)

```bash
# Preview changes without applying
ansible-playbook playbook.yml --check

# Preview with detailed output
ansible-playbook playbook.yml --check --diff
```

## Post-Deployment

### Verify Setup

1. **Test SSH Access**
   ```bash
   ssh admin@your-server-ip
   ```

2. **Check Firewall Status**
   ```bash
   sudo ufw status verbose
   ```

3. **Verify Fail2Ban**
   ```bash
   sudo fail2ban-client status sshd
   ```

4. **Test Cloudflare Tunnel** (if configured)
   ```bash
   ssh admin@ssh.yourdomain.com
   ```

### Access Monitoring

If you deployed the monitoring stack:

- **Grafana**: https://grafana.yourdomain.com (if using tunnel) or http://server-ip:3000
  - Default login: admin / admin (change immediately!)
- **Prometheus**: http://server-ip:9090
- **Alertmanager**: http://server-ip:9093

### Final Lockdown

After verifying Cloudflare Tunnel works:

```bash
# Close SSH port (access only via tunnel)
sudo ufw delete allow 22/tcp

# Verify
sudo ufw status
```

## Troubleshooting

### SSH Connection Issues

```bash
# Check SSH status
sudo systemctl status sshd

# View SSH logs
sudo journalctl -u sshd -n 50

# Test SSH configuration
sudo sshd -t
```

### Firewall Issues

```bash
# Check UFW status
sudo ufw status numbered

# View UFW logs
sudo tail -f /var/log/ufw.log

# Temporarily disable UFW (emergency only!)
sudo ufw disable
```

### Fail2Ban Not Banning

```bash
# Check Fail2Ban status
sudo fail2ban-client status sshd

# View banned IPs
sudo fail2ban-client get sshd banip

# Check logs
sudo tail -f /var/log/fail2ban.log
```

### Monitoring Services Down

```bash
# Check service status
sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status alertmanager

# View logs
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f
```

## Advanced Usage

### Custom Application Users

Add to `group_vars/all.yml`:

```yaml
app_users:
  - name: "webapp"
    comment: "Web Application User"
    system: true
    shell: "/usr/sbin/nologin"
```

### Additional Firewall Rules

```yaml
ufw_allowed_ports:
  - { port: 80, proto: tcp }
  - { port: 443, proto: tcp }
  - { port: 8080, proto: tcp }
```

### Custom Fail2Ban Jails

```yaml
fail2ban_custom_jails:
  - name: "nginx-limit-req"
    port: "http,https"
    filter: "nginx-limit-req"
    logpath: "/var/log/nginx/error.log"
```

### Remote Backups (S3/DigitalOcean Spaces)

```yaml
backup_remote_enabled: true
backup_remote_type: "s3"
backup_remote_bucket: "my-backups"
backup_remote_access_key: "your-key"
backup_remote_secret_key: "your-secret"
```

## Security Notes

### ⚠️ Important Security Considerations

1. **Never commit sensitive data**
   - SSH private keys
   - Cloudflare tokens
   - API credentials
   - Server IP addresses
   - Actual configuration files

2. **Use strong passwords**
   - Generate strong passwords for all users
   - Use password managers
   - Rotate credentials regularly

3. **SSH key management**
   - Use Ed25519 keys (more secure)
   - Protect private keys with passphrases
   - Never share private keys
   - Rotate keys periodically

4. **Cloudflare Tunnel security**
   - Enable Zero Trust authentication
   - Use WARP for SSH access
   - Regularly review access logs
   - Rotate tunnel tokens

5. **Monitor your systems**
   - Review Fail2Ban logs regularly
   - Check Prometheus alerts
   - Monitor system metrics
   - Keep systems updated

6. **Test before production**
   - Always test in a development environment
   - Use `--check` mode first
   - Keep backups before changes
   - Document your changes

## Architecture

```
┌─────────────────────────────────────────────┐
│          Cloudflare Network                 │
│  ┌──────────────────────────────────────┐   │
│  │    Cloudflare Tunnel + Zero Trust    │   │
│  └──────────────────────────────────────┘   │
└─────────────────┬───────────────────────────┘
                  │ Encrypted Tunnel
┌─────────────────▼───────────────────────────┐
│          Ubuntu Server                      │
│  ┌──────────────────────────────────────┐   │
│  │         cloudflared                  │   │
│  └──────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┐   │
│  │  SSH  │  Apps  │  Monitoring        │   │
│  └──────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┐   │
│  │     UFW Firewall (deny all)          │   │
│  └──────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┐   │
│  │         Fail2Ban                     │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

## File Structure

```
.
├── README.md                    # This file
├── DEPLOYMENT_GUIDE.md          # Step-by-step deployment guide
├── ansible.cfg                  # Ansible configuration
├── inventory.ini.example        # Example inventory
├── playbook.yml                 # Main security playbook
├── rollback.yml                 # Rollback playbook
├── backup-restore.yml           # Backup/restore playbook
├── monitoring.yml               # Monitoring stack playbook
├── group_vars/
│   ├── all.yml.example          # Main configuration
│   └── monitoring.yml.example   # Monitoring configuration
├── roles/
│   ├── common/                  # System updates & base config
│   ├── users/                   # User management
│   ├── ssh/                     # SSH hardening
│   ├── firewall/                # UFW configuration
│   ├── fail2ban/                # Fail2Ban setup
│   ├── cloudflared/             # Cloudflare Tunnel
│   ├── backup/                  # Backup automation
│   ├── restore/                 # Restore automation
│   ├── prometheus/              # Prometheus setup
│   ├── node_exporter/           # System metrics
│   ├── grafana/                 # Dashboards
│   ├── alertmanager/            # Alert management
│   └── monitoring_tunnel/       # Monitoring via tunnel
├── files/
│   └── ssh_keys/                # SSH public keys
└── scripts/
    ├── quick-setup.sh           # Quick deployment script
    └── create-repo.sh           # Repository structure setup
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: https://github.com/annurdien/ubuntu-server-setup/issues
- **Discussions**: https://github.com/annurdien/ubuntu-server-setup/discussions

## Acknowledgments

Based on the three-part Ubuntu server security article series covering:
1. Initial server hardening and security setup
2. Cloudflare Tunnel integration with Zero Trust
3. Monitoring with Prometheus and Grafana

## Related Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ubuntu Security Guide](https://ubuntu.com/security)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

**⚡ Quick Commands Reference**

```bash
# Deploy everything
ansible-playbook playbook.yml

# Setup monitoring
ansible-playbook monitoring.yml

# Create backup
ansible-playbook backup-restore.yml

# Rollback changes
ansible-playbook rollback.yml

# Check connection
ansible all -m ping

# Dry run
ansible-playbook playbook.yml --check
```

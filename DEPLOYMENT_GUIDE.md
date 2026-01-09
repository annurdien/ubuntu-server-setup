# Ubuntu Server Security - Deployment Guide

Complete step-by-step guide for deploying secure Ubuntu servers with Ansible automation.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Preparation](#environment-preparation)
3. [Configuration Setup](#configuration-setup)
4. [Initial Deployment](#initial-deployment)
5. [Cloudflare Tunnel Setup](#cloudflare-tunnel-setup)
6. [Zero Trust Configuration](#zero-trust-configuration)
7. [Monitoring Stack](#monitoring-stack)
8. [Final Lockdown](#final-lockdown)
9. [Testing & Verification](#testing-verification)
10. [Maintenance](#maintenance)

---

## Prerequisites

### Checklist

- [ ] Fresh Ubuntu 20.04 or 22.04 LTS server
- [ ] Root or sudo access to the server
- [ ] Control machine with Ansible 2.10+ installed
- [ ] SSH key pair generated (Ed25519 recommended)
- [ ] Cloudflare account (for tunnel features)
- [ ] Domain name configured in Cloudflare (optional)
- [ ] Email account for alerts (optional)

### Required Software

**On Control Machine:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y ansible git python3-pip

# Verify installation
ansible --version  # Should be 2.10 or higher
```

**On Target Server:**
- Fresh Ubuntu 20.04/22.04 LTS installation
- Internet connectivity
- SSH access enabled

---

## Environment Preparation

### Step 1: Clone Repository

```bash
git clone https://github.com/annurdien/ubuntu-server-setup.git
cd ubuntu-server-setup
```

### Step 2: Generate SSH Keys

If you don't have SSH keys:

```bash
# Generate Ed25519 key (recommended)
ssh-keygen -t ed25519 -C "admin@server" -f ~/.ssh/id_ed25519

# Or RSA key (if Ed25519 not supported)
ssh-keygen -t rsa -b 4096 -C "admin@server" -f ~/.ssh/id_rsa
```

**Important**: Keep your private key secure and never share it!

### Step 3: Copy Public Key

```bash
# Copy to Ansible files directory
cp ~/.ssh/id_ed25519.pub files/ssh_keys/admin_id_ed25519.pub

# Verify
cat files/ssh_keys/admin_id_ed25519.pub
```

---

## Configuration Setup

### Step 1: Create Inventory File

```bash
cp inventory.ini.example inventory.ini
vim inventory.ini
```

**Example inventory.ini:**
```ini
[servers]
prod-server1 ansible_host=203.0.113.10 ansible_user=root
prod-server2 ansible_host=203.0.113.20 ansible_user=root

[servers:vars]
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3

[monitoring]
prod-server1 ansible_host=203.0.113.10 ansible_user=root
```

**Security Note**: Never commit `inventory.ini` to version control!

### Step 2: Configure Main Variables

```bash
cp group_vars/all.yml.example group_vars/all.yml
vim group_vars/all.yml
```

**Essential settings to update:**

```yaml
# 1. Admin User
admin_user:
  name: "admin"  # Change to your preferred username
  password: "{{ 'YourStrongPassword123!' | password_hash('sha512') }}"
  shell: "/bin/bash"
  groups: "sudo"
  ssh_key: "{{ lookup('file', 'files/ssh_keys/admin_id_ed25519.pub') }}"

# 2. System Configuration
timezone: "America/New_York"  # Your timezone

# 3. SSH Configuration (keep these secure defaults)
ssh_port: 22
ssh_permit_root_login: "no"
ssh_password_authentication: "no"
ssh_pubkey_authentication: "yes"

# 4. Fail2Ban
fail2ban_enabled: true
fail2ban_bantime: 3600
fail2ban_maxretry: 5
fail2ban_destemail: "your-email@example.com"

# 5. Cloudflare (if using tunnel)
cloudflare_tunnel_token: "your-tunnel-token"  # Get from Cloudflare dashboard
cloudflare_tunnel_id: "your-tunnel-id"
domain_name: "example.com"

# 6. Backup Configuration
backup_enabled: true
backup_retention_days: 30
backup_directory: "/opt/backups"
```

### Step 3: Configure Monitoring (Optional)

```bash
cp group_vars/monitoring.yml.example group_vars/monitoring.yml
vim group_vars/monitoring.yml
```

**Update monitoring settings:**

```yaml
# Grafana
grafana_admin_user: "admin"
grafana_admin_password: "ChangeThisPassword!"
grafana_domain: "grafana.example.com"

# Alertmanager (for email alerts)
alertmanager_smtp_enabled: true
alertmanager_smtp_smarthost: "smtp.gmail.com:587"
alertmanager_smtp_from: "alerts@example.com"
alertmanager_smtp_auth_username: "your-email@gmail.com"
alertmanager_smtp_auth_password: "your-app-password"

alertmanager_receivers:
  - name: "email"
    email_configs:
      - to: "admin@example.com"
```

---

## Initial Deployment

### Step 1: Test Connection

```bash
# Test connectivity to all servers
ansible all -m ping

# Expected output:
# prod-server1 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

**If connection fails:**
```bash
# Debug connection
ansible all -m ping -vvv

# Common issues:
# - Check server IP is correct
# - Verify SSH key has access
# - Ensure server is reachable
```

### Step 2: Syntax Check

```bash
# Validate playbook syntax
ansible-playbook playbook.yml --syntax-check

# Should show: playbook: playbook.yml
```

### Step 3: Dry Run (Check Mode)

```bash
# Preview changes without applying
ansible-playbook playbook.yml --check --diff

# Review output carefully
# Look for any errors or unexpected changes
```

### Step 4: Run Security Setup

```bash
# Full deployment
ansible-playbook playbook.yml

# Or run specific parts with tags
ansible-playbook playbook.yml --tags common,users,ssh

# With verbose output
ansible-playbook playbook.yml -v
```

**Deployment takes approximately 10-15 minutes.**

### Step 5: Create Initial Backup

```bash
ansible-playbook backup-restore.yml
# Select option 1 (Create a new backup)
```

---

## Cloudflare Tunnel Setup

### Step 1: Create Cloudflare Tunnel

1. Log in to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Access** → **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** and name it (e.g., `prod-server-tunnel`)
5. Install connector: **Note the tunnel token** (starts with `eyJ...`)
6. Copy the tunnel ID from the URL or dashboard

### Step 2: Configure Tunnel Routes

In Cloudflare dashboard, add public hostnames:

| Subdomain | Domain | Service |
|-----------|--------|---------|
| ssh | example.com | ssh://localhost:22 |
| app | example.com | http://localhost:3000 |
| api | example.com | http://localhost:8080 |

### Step 3: Update Configuration

Edit `group_vars/all.yml`:

```yaml
cloudflare_tunnel_token: "eyJhbGc..."  # Your tunnel token
cloudflare_tunnel_id: "12345678-1234-1234-1234-123456789abc"
domain_name: "example.com"

cloudflare_applications:
  - name: "ssh"
    service: "ssh://localhost:22"
    hostname: "ssh.example.com"
    public: false
  
  - name: "webapp"
    service: "http://localhost:3000"
    hostname: "app.example.com"
    public: false
```

### Step 4: Deploy Cloudflared

```bash
# Run cloudflared role
ansible-playbook playbook.yml --tags cloudflared

# Verify service is running
ansible servers -m shell -a "systemctl status cloudflared"
```

---

## Zero Trust Configuration

### Step 1: Create Access Application

1. Go to **Access** → **Applications** → **Add an application**
2. Select **Self-hosted**
3. Configure application:
   - **Application name**: SSH Access
   - **Subdomain**: ssh
   - **Domain**: example.com
   - **Session Duration**: 24 hours

### Step 2: Add Access Policy

Create policy to control who can access:

**Example policy:**
- **Policy name**: Admin Access
- **Action**: Allow
- **Include**: Emails ending in @yourcompany.com
- Or specific email addresses

### Step 3: Configure WARP (for SSH)

**On your local machine:**

1. Install Cloudflare WARP:
   ```bash
   # Ubuntu/Debian
   curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
   sudo apt update && sudo apt install cloudflare-warp
   ```

2. Register WARP:
   ```bash
   warp-cli registration new
   warp-cli connect
   ```

3. Enable Gateway:
   ```bash
   warp-cli set-mode proxy
   warp-cli connect
   ```

### Step 4: Test Tunnel Access

```bash
# SSH through tunnel (with WARP connected)
ssh admin@ssh.example.com

# Should prompt for Cloudflare authentication on first access
```

---

## Monitoring Stack

### Step 1: Deploy Monitoring

```bash
# Deploy full monitoring stack
ansible-playbook monitoring.yml

# Or specific components
ansible-playbook monitoring.yml --tags prometheus
ansible-playbook monitoring.yml --tags grafana
```

### Step 2: Access Grafana

1. **Direct access** (before closing ports):
   ```
   http://your-server-ip:3000
   ```

2. **Via Cloudflare Tunnel** (recommended):
   ```
   https://grafana.example.com
   ```

3. **Login**:
   - Username: `admin`
   - Password: From `grafana_admin_password` in config

**IMPORTANT**: Change the default password immediately!

### Step 3: Verify Metrics

1. Open Grafana
2. Navigate to **Dashboards**
3. Open "Node Exporter Full" or "System Overview"
4. Verify metrics are being collected

### Step 4: Test Alerts

Check Prometheus alerts:
```
http://your-server-ip:9090/alerts
```

Check Alertmanager:
```
http://your-server-ip:9093
```

---

## Final Lockdown

### Step 1: Verify All Access Methods

**Before closing SSH port, verify:**

- [ ] SSH through Cloudflare Tunnel works
- [ ] Admin user can login with SSH key
- [ ] Cloudflared service is running
- [ ] Monitoring is accessible (if deployed)
- [ ] You have backup access method

**Test thoroughly!**

```bash
# Keep current SSH session open
# Open NEW terminal and test
ssh admin@ssh.example.com

# If successful, proceed
# If not, troubleshoot before closing port
```

### Step 2: Close SSH Port

Only after verifying tunnel access:

```bash
# On the server
sudo ufw delete allow 22/tcp

# Or via Ansible
ansible servers -m ufw -a "rule=allow port=22 proto=tcp delete=yes" --become

# Verify
sudo ufw status numbered
```

### Step 3: Close Monitoring Ports

```bash
# Close direct access to monitoring
sudo ufw deny 9090/tcp  # Prometheus
sudo ufw deny 3000/tcp  # Grafana
sudo ufw deny 9093/tcp  # Alertmanager
sudo ufw deny 9100/tcp  # Node Exporter

# Access only via Cloudflare Tunnel
```

### Step 4: Final Verification

```bash
# Check firewall rules
sudo ufw status verbose

# Should show:
# - Default: deny (incoming)
# - Default: allow (outgoing)
# - No SSH port open
```

---

## Testing & Verification

### Security Checks

```bash
# 1. SSH Configuration
sudo sshd -t  # Check SSH config syntax
sudo systemctl status sshd

# 2. Firewall Status
sudo ufw status verbose

# 3. Fail2Ban Status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# 4. Cloudflared Status
sudo systemctl status cloudflared
sudo journalctl -u cloudflared -n 50

# 5. Check open ports
sudo ss -tlnp
```

### Monitoring Checks

```bash
# 1. Prometheus
curl http://localhost:9090/-/healthy

# 2. Node Exporter
curl http://localhost:9100/metrics

# 3. Grafana
sudo systemctl status grafana-server

# 4. Alertmanager
curl http://localhost:9093/-/healthy
```

### Access Verification

```bash
# 1. SSH through tunnel
ssh admin@ssh.example.com

# 2. Check web applications
curl https://app.example.com

# 3. Grafana
open https://grafana.example.com
```

---

## Maintenance

### Regular Tasks

**Daily:**
- Monitor alert notifications
- Check Fail2Ban for suspicious activity

**Weekly:**
- Review Grafana dashboards
- Check system metrics trends
- Review backup logs

**Monthly:**
- Update systems (or let unattended-upgrades handle)
- Rotate logs if needed
- Test backup restore
- Review and update firewall rules

### Update Systems

```bash
# Update system packages
ansible-playbook playbook.yml --tags common

# Check for security updates
ansible servers -m shell -a "apt list --upgradable" --become
```

### Backup Management

```bash
# Create manual backup
ansible-playbook backup-restore.yml  # Option 1

# List backups
ansible-playbook backup-restore.yml  # Option 4

# Clean old backups
ansible-playbook backup-restore.yml  # Option 5
```

### Certificate Rotation

Cloudflare Tunnel handles certificates automatically, but verify:

```bash
# Check tunnel connection
sudo cloudflared tunnel info

# View tunnel logs
sudo journalctl -u cloudflared -f
```

### Monitoring Maintenance

```bash
# Restart services if needed
sudo systemctl restart prometheus
sudo systemctl restart grafana-server
sudo systemctl restart alertmanager

# Clear old metrics (Prometheus)
# Retention is configured, automatic cleanup
```

---

## Emergency Procedures

### Lost SSH Access

**If you can't connect via tunnel:**

1. Access via cloud provider console (if available)
2. Temporarily open SSH port via provider firewall
3. Fix tunnel configuration
4. Close SSH port again

### Rollback Configuration

```bash
# Interactive rollback
ansible-playbook rollback.yml

# Select what to rollback:
# 1. SSH only
# 2. Firewall only
# 3. Everything
```

### Restore from Backup

```bash
# Restore latest backup
ansible-playbook backup-restore.yml  # Option 2

# Or specific backup
ansible-playbook backup-restore.yml  # Option 3
```

### Reset Firewall

**Emergency only - opens all ports:**

```bash
# Via console access
sudo ufw disable
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable
```

---

## Troubleshooting

### Common Issues

**Issue: Can't connect via SSH after deployment**
```bash
# Check SSH is running
sudo systemctl status sshd

# Check firewall
sudo ufw status

# Check logs
sudo tail -f /var/log/auth.log
```

**Issue: Cloudflared not working**
```bash
# Check service
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -n 100

# Verify configuration
sudo cat /etc/cloudflared/config.yml

# Restart service
sudo systemctl restart cloudflared
```

**Issue: Monitoring metrics not showing**
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Node Exporter
curl http://localhost:9100/metrics

# Restart services
sudo systemctl restart prometheus node_exporter
```

**Issue: Grafana can't connect to Prometheus**
```bash
# Check Grafana datasource
sudo cat /etc/grafana/provisioning/datasources/prometheus.yml

# Test connection from Grafana host
curl http://localhost:9090/api/v1/query?query=up
```

---

## Best Practices

1. **Always test in development first**
2. **Use version control for configurations**
3. **Document any custom changes**
4. **Maintain regular backups**
5. **Monitor security alerts**
6. **Keep systems updated**
7. **Use strong, unique passwords**
8. **Enable MFA where possible**
9. **Regularly review access logs**
10. **Test disaster recovery procedures**

---

## Support & Resources

- **GitHub Issues**: https://github.com/annurdien/ubuntu-server-setup/issues
- **Ansible Docs**: https://docs.ansible.com/
- **Cloudflare Docs**: https://developers.cloudflare.com/
- **Prometheus Docs**: https://prometheus.io/docs/
- **Grafana Docs**: https://grafana.com/docs/

---

## Checklist Summary

- [ ] Prerequisites installed
- [ ] SSH keys generated and copied
- [ ] Inventory configured
- [ ] Variables configured (all.yml, monitoring.yml)
- [ ] Connection tested
- [ ] Playbook syntax validated
- [ ] Initial backup created
- [ ] Security setup deployed
- [ ] Cloudflare Tunnel configured
- [ ] Zero Trust policies created
- [ ] WARP installed and configured
- [ ] Tunnel access verified
- [ ] Monitoring deployed
- [ ] Grafana password changed
- [ ] Alert notifications tested
- [ ] SSH port closed (after verification)
- [ ] Final security checks completed
- [ ] Documentation updated with your specifics

---

**Congratulations!** Your Ubuntu server is now secured with industry best practices.

Remember: Security is an ongoing process. Stay vigilant, keep systems updated, and regularly review your security posture.

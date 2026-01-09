# SSH Keys Directory

This directory should contain SSH public keys for admin and application users.

## Required Files

1. **admin_id_ed25519.pub** - SSH public key for admin user
   - Generate with: `ssh-keygen -t ed25519 -C "admin@server" -f admin_id_ed25519`
   - Only place the `.pub` file here (keep private key secure)

## Adding Keys

1. Generate a new SSH key pair:
   ```bash
   ssh-keygen -t ed25519 -C "user@server" -f username_id_ed25519
   ```

2. Copy the public key (`.pub`) to this directory:
   ```bash
   cp username_id_ed25519.pub files/ssh_keys/
   ```

3. Update `group_vars/all.yml` to reference the key:
   ```yaml
   admin_user:
     ssh_key: "{{ lookup('file', 'files/ssh_keys/admin_id_ed25519.pub') }}"
   ```

## Security Notes

- **NEVER** commit private keys to version control
- Only `.pub` (public) keys should be in this directory
- Private keys should remain on your local machine
- Use strong passphrases for private keys
- Regularly rotate keys for enhanced security

## Example Structure

```
files/ssh_keys/
├── .gitkeep
├── README.md
├── admin_id_ed25519.pub
├── user1_id_ed25519.pub
└── user2_id_ed25519.pub
```

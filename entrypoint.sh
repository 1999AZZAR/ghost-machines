#!/bin/bash
set -e

# Generate SSH host keys if missing
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A >/dev/null 2>&1 || true
fi

# Configure SSH Password Authentication
if [ "${SSH_PASSWORD_AUTH,,}" = "false" ] || [ "${SSH_PASSWORD_AUTH}" = "0" ]; then
    sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#*PermitEmptyPasswords .*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
else
    sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
fi

# Inject / Fix permissions for authorized_keys if present
setup_user_ssh() {
    local USER_DIR="$1"
    local USER_NAME="$2"
    if [ -d "$USER_DIR" ]; then
        mkdir -p "$USER_DIR/.ssh"
        chmod 700 "$USER_DIR/.ssh"
        if [ -f "$USER_DIR/.ssh/authorized_keys" ]; then
            chmod 600 "$USER_DIR/.ssh/authorized_keys"
        fi
        chown -R "$USER_NAME:$USER_NAME" "$USER_DIR/.ssh" 2>/dev/null || true
    fi
}

setup_user_ssh "/root" "root"
TARGET_USER="${GHOST_USER:-developer}"
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ] && [ -d "/home/$TARGET_USER" ]; then
    setup_user_ssh "/home/$TARGET_USER" "$TARGET_USER"
fi

exec "$@"

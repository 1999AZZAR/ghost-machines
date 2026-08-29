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
        chmod 755 "$USER_DIR" 2>/dev/null || true
        mkdir -p "$USER_DIR/.ssh" 2>/dev/null || true
        chmod 700 "$USER_DIR/.ssh" 2>/dev/null || true
        if [ "$USER_DIR" != "/root" ] && [ -f /root/.ssh/authorized_keys ]; then
            cp -f /root/.ssh/authorized_keys "$USER_DIR/.ssh/authorized_keys" 2>/dev/null || true
        fi
        if [ -f "$USER_DIR/.ssh/authorized_keys" ]; then
            chmod 600 "$USER_DIR/.ssh/authorized_keys" 2>/dev/null || true
        fi
        chown -R "$USER_NAME:$USER_NAME" "$USER_DIR/.ssh" 2>/dev/null || true
        echo "$USER_NAME:ghost" | chpasswd 2>/dev/null || true
    fi
}

# Configure MCP configs and Google Conductor plugins across all harnesses
setup_user_harnesses_and_conductor() {
    local USER_DIR="$1"
    local USER_NAME="$2"
    if [ -d "$USER_DIR" ]; then
        mkdir -p "$USER_DIR/.gemini" "$USER_DIR/.mcp" "$USER_DIR/.config/opencode" "$USER_DIR/.config/kilo" "$USER_DIR/.agents/plugins" "$USER_DIR/.agents/skills" "$USER_DIR/.local/share" "$USER_DIR/.local/bin"

        # Copy skeleton bash environment if .bashrc missing or empty
        if [ ! -s "$USER_DIR/.bashrc" ] && [ -f /root/.bashrc ]; then
            cp /root/.bashrc "$USER_DIR/.bashrc"
        fi
        if [ ! -d "$USER_DIR/.oh-my-bash" ] && [ -d /root/.oh-my-bash ]; then
            cp -r /root/.oh-my-bash "$USER_DIR/.oh-my-bash"
        fi
        if [ ! -d "$USER_DIR/.local/share/neofetch_ascii" ] && [ -d /root/.local/share/neofetch_ascii ]; then
            cp -r /root/.local/share/neofetch_ascii "$USER_DIR/.local/share/neofetch_ascii"
        fi
        if [ ! -d "$USER_DIR/.alias-hub" ] && [ -d /root/.alias-hub ]; then
            cp -r /root/.alias-hub "$USER_DIR/.alias-hub"
        fi
        if [ -f /root/.bash_aliases ] && [ ! -f "$USER_DIR/.bash_aliases" ]; then
            cp /root/.bash_aliases "$USER_DIR/.bash_aliases"
        fi

        # Sync MCP configs if missing
        if [ ! -f "$USER_DIR/.mcp/config.json" ] && [ -f /root/.mcp/config.json ]; then
            cp /root/.mcp/config.json "$USER_DIR/.mcp/config.json"
        fi
        if [ ! -f "$USER_DIR/.config/opencode/config.json" ] && [ -f /root/.config/opencode/config.json ]; then
            cp /root/.config/opencode/config.json "$USER_DIR/.config/opencode/config.json"
        fi
        if [ ! -f "$USER_DIR/.config/kilo/config.json" ] && [ -f /root/.config/kilo/config.json ]; then
            cp /root/.config/kilo/config.json "$USER_DIR/.config/kilo/config.json"
        fi

        # Link Google Conductor repository & global skills
        if [ -d /opt/conductor ]; then
            ln -sfn /opt/conductor "$USER_DIR/.agents/plugins/conductor"
            ln -sfn /opt/conductor "$USER_DIR/.gemini/config/plugins/conductor"
            for skill in conductor-setup conductor-new-track conductor-implement conductor-status conductor-revert conductor-review; do
                if [ -d "/opt/conductor/skills/$skill" ]; then
                    ln -sfn "$USER_DIR/.agents/plugins/conductor/skills/$skill" "$USER_DIR/.agents/skills/$skill"
                fi
            done
        fi
        chown -R "$USER_NAME:$USER_NAME" "$USER_DIR" 2>/dev/null || true
    fi
}

if [ -f /usr/local/bin/agy ]; then
    ln -sf /usr/local/bin/agy /usr/local/bin/antigravity 2>/dev/null || true
fi
if [ -f /root/.bun/bin/bun ]; then
    ln -sf /root/.bun/bin/bun /usr/local/bin/bun 2>/dev/null || true
fi

TARGET_USER="${GHOST_USER:-developer}"
if [ -n "$HOST_UID" ] && [ -n "$HOST_GID" ] && [ "$TARGET_USER" != "root" ] && id "$TARGET_USER" >/dev/null 2>&1; then
    groupmod -g "$HOST_GID" "$TARGET_USER" 2>/dev/null || true
    usermod -u "$HOST_UID" -g "$HOST_GID" "$TARGET_USER" 2>/dev/null || true
fi

setup_user_ssh "/root" "root"
setup_user_harnesses_and_conductor "/root" "root"

if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ] && [ -d "/home/$TARGET_USER" ]; then
    setup_user_ssh "/home/$TARGET_USER" "$TARGET_USER"
    setup_user_harnesses_and_conductor "/home/$TARGET_USER" "$TARGET_USER"
fi

exec "$@"

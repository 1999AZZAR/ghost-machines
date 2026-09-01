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
        if [ "$USER_NAME" != "root" ]; then
            mkdir -p /etc/sudoers.d
            echo "$USER_NAME ALL=(ALL) ALL" > "/etc/sudoers.d/$USER_NAME"
            chmod 0440 "/etc/sudoers.d/$USER_NAME"
        fi
    fi
}

# Configure MCP configs and Google Conductor plugins across all harnesses
setup_user_harnesses_and_conductor() {
    local USER_DIR="$1"
    local USER_NAME="$2"
    if [ -d "$USER_DIR" ]; then
        mkdir -p "$USER_DIR/.gemini/config/plugins" "$USER_DIR/.mcp" "$USER_DIR/.config/opencode" "$USER_DIR/.config/kilo" "$USER_DIR/.agents/plugins" "$USER_DIR/.agents/skills" "$USER_DIR/.local/share" "$USER_DIR/.local/state" "$USER_DIR/.local/bin" "$USER_DIR/.local/share/kilo" "$USER_DIR/.local/share/opencode" "$USER_DIR/.config/opencode" "$USER_DIR/.config/kilo"

        # Copy skeleton bash environment if .bashrc missing or empty
        if [ ! -s "$USER_DIR/.bashrc" ] && [ -f /root/.bashrc ]; then
            cp /root/.bashrc "$USER_DIR/.bashrc"
        fi
        if [ -f "$USER_DIR/.bashrc" ]; then
            sed -i "s|/root/|$USER_DIR/|g" "$USER_DIR/.bashrc"
        fi

        # Oh-My-Bash setup
        if [ ! -d "$USER_DIR/.oh-my-bash" ] && [ -d /root/.oh-my-bash ]; then
            cp -r /root/.oh-my-bash "$USER_DIR/.oh-my-bash"
        fi

        # Alias-Hub setup
        if [ ! -d "$USER_DIR/alias-hub" ] && [ -d /root/alias-hub ]; then
            cp -r /root/alias-hub "$USER_DIR/alias-hub"
        fi
        if [ ! -d "$USER_DIR/.alias-hub" ] && [ -d /root/alias-hub ]; then
            cp -r /root/alias-hub "$USER_DIR/.alias-hub"
        fi

        # Neofetch ASCII setup
        if [ ! -d "$USER_DIR/.local/share/neofetch_ascii" ] && [ -d /root/.local/share/neofetch_ascii ]; then
            cp -r /root/.local/share/neofetch_ascii "$USER_DIR/.local/share/neofetch_ascii"
        fi
        if [ -d "$USER_DIR/.local/share/neofetch_ascii" ]; then
            mkdir -p "$USER_DIR/Pictures" "$USER_DIR/.config/neofetch" "$USER_DIR/.config/fastfetch"
            ln -sfn "$USER_DIR/.local/share/neofetch_ascii/ascii" "$USER_DIR/Pictures/ascii"
            [ -f "$USER_DIR/.local/share/neofetch_ascii/config.conf" ] && cp -f "$USER_DIR/.local/share/neofetch_ascii/config.conf" "$USER_DIR/.config/neofetch/config.conf"
            if [ -f /root/.config/fastfetch/config.jsonc ] && [ ! -f "$USER_DIR/.config/fastfetch/config.jsonc" ]; then
                cp /root/.config/fastfetch/config.jsonc "$USER_DIR/.config/fastfetch/config.jsonc"
            fi
            if [ -f "$USER_DIR/.config/fastfetch/config.jsonc" ]; then
                sed -i 's/"format": "{1}"/"format": "{all}"/g' "$USER_DIR/.config/fastfetch/config.jsonc"
            fi
            chmod +x "$USER_DIR/.local/share/neofetch_ascii/ascii/loopers.sh" 2>/dev/null || true
        fi

        # Bash Aliases & Helper Functions setup
        cat <<'EOF' > "$USER_DIR/.bash_aliases"
shopt -s expand_aliases 2>/dev/null || true

# Global Ghost Aliases
alias cls='clear'
alias fetch='fastfetch'
alias neofetch='fastfetch'

# Custom ASCII Caller Function (neofetch_ascii)
ascii() {
    local original_dir=$(pwd)
    cd "$HOME/Pictures/ascii" 2>/dev/null || { echo "Error: $HOME/Pictures/ascii directory not found."; return 1; }
    ./loopers.sh "$@"
    cd "$original_dir" 2>/dev/null || return 1
}

# Fastfetch with random ASCII art
rfetch() {
    local ascii_file
    ascii_file=$(find "$HOME/Pictures/ascii" -maxdepth 1 -name "*.txt" 2>/dev/null | shuf -n 1)
    if [ -n "$ascii_file" ]; then
        fastfetch --logo "$ascii_file" "$@"
    else
        fastfetch "$@"
    fi
}

# Alias-Hub Loader
export ALIASES_DIR="$HOME/alias-hub"
if [ -d "$ALIASES_DIR" ]; then
    [ -f "$ALIASES_DIR/script/helpers.sh" ] && source "$ALIASES_DIR/script/helpers.sh" 2>/dev/null || true
    for file in "$ALIASES_DIR"/*.alias; do
        [ -f "$file" ] && source "$file" 2>/dev/null || true
    done
fi
EOF

        # Ensure .bashrc sources .bash_aliases
        if [ -f "$USER_DIR/.bashrc" ] && ! grep -q ".bash_aliases" "$USER_DIR/.bashrc" 2>/dev/null; then
            cat <<'EOF' >> "$USER_DIR/.bashrc"

if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi
EOF
        fi

        # Login shell profile setup
        if [ ! -f "$USER_DIR/.profile" ] || ! grep -q ".bash_aliases" "$USER_DIR/.profile" 2>/dev/null; then
            cat <<'EOF' > "$USER_DIR/.profile"
# ~/.profile: executed by Bourne-compatible login shells.
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi
if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi
EOF
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

        # RTK Universal Rewrite Hook setup for all AI Harnesses
        mkdir -p "$USER_DIR/.config/rtk" "$USER_DIR/.gemini/config/hooks" "$USER_DIR/.claude/hooks"
        cat <<'EOF' > "$USER_DIR/.config/rtk/rtk-rewrite.sh"
#!/usr/bin/env bash
# Universal RTK Rewrite Hook for AI Harnesses (Antigravity, OpenCode, Kilo, Claude)
if ! command -v jq &>/dev/null || ! command -v rtk &>/dev/null; then
  exit 0
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.CommandLine // .arguments.command // .arguments.CommandLine // .command // empty' 2>/dev/null)

if [ -z "$CMD" ]; then
  exit 0
fi

REWRITTEN=$(rtk rewrite "$CMD" 2>/dev/null || true)

if [ -z "$REWRITTEN" ] || [ "$CMD" = "$REWRITTEN" ]; then
  exit 0
fi

ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // .arguments // .')
UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$REWRITTEN" '
  if has("CommandLine") then .CommandLine = $cmd
  elif has("command") then .command = $cmd
  else .command = $cmd end
')

jq -n \
  --argjson updated "$UPDATED_INPUT" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "RTK auto-rewrite",
      "updatedInput": $updated
    }
  }'
EOF
        chmod +x "$USER_DIR/.config/rtk/rtk-rewrite.sh"
        cp -f "$USER_DIR/.config/rtk/rtk-rewrite.sh" "$USER_DIR/.gemini/config/hooks/rtk-rewrite.sh"
        cp -f "$USER_DIR/.config/rtk/rtk-rewrite.sh" "$USER_DIR/.claude/hooks/rtk-rewrite.sh"
        chmod +x "$USER_DIR/.gemini/config/hooks/rtk-rewrite.sh" "$USER_DIR/.claude/hooks/rtk-rewrite.sh" 2>/dev/null || true

        # Antigravity Hooks config
        if [ ! -f "$USER_DIR/.gemini/config/hooks.json" ]; then
            cat <<'EOF' > "$USER_DIR/.gemini/config/hooks.json"
{
  "rtk-rewrite": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "run_command",
        "type": "command",
        "command": "~/.gemini/config/hooks/rtk-rewrite.sh"
      }
    ]
  }
}
EOF
        fi

        # Claude / OpenCode settings.json hook integration
        if [ ! -f "$USER_DIR/.claude/settings.json" ]; then
            cat <<'EOF' > "$USER_DIR/.claude/settings.json"
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/rtk-rewrite.sh"
          }
        ]
      }
    ]
  }
}
EOF
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
if [ -f /usr/local/go/bin/go ]; then
    ln -sf /usr/local/go/bin/go /usr/local/bin/go 2>/dev/null || true
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt 2>/dev/null || true
fi
if [ -f /usr/local/cargo/bin/cargo ]; then
    ln -sf /usr/local/cargo/bin/cargo /usr/local/bin/cargo 2>/dev/null || true
    ln -sf /usr/local/cargo/bin/rustc /usr/local/bin/rustc 2>/dev/null || true
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

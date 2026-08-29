# ==============================================================================
# ROCI GHOST MACHINE - MASTER TEMPLATE (UBUNTU)
# ==============================================================================
# Build: docker build -t ubuntu-template:latest .
# ==============================================================================

FROM ubuntu:latest

# Build Arguments
ARG GHOST_USER=developer
ARG HOST_UID=1000
ARG HOST_GID=1000

# 1. Environment & UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# 2. Base System & Build Tools
RUN apt-get update && apt-get install -y \
    curl gnupg git wget unzip software-properties-common sudo \
    build-essential gdb make cmake \
    python3 python-is-python3 python3-pip python3-venv \
    htop btop net-tools glances sysstat inxi ncdu tree \
    zip p7zip-full nmap lsof xclip \
    nnn fzf ripgrep tmux \
    bat eza zoxide fd-find jq \
    kitty kitty-terminfo \
    openssh-server \
    && mkdir -p /var/run/sshd \
    && ln -s /usr/bin/batcat /usr/local/bin/bat \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd

# 3. Node.js (Latest Current)
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs

# 4. Go Runtime
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then GO_ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then GO_ARCH="arm64"; else GO_ARCH="amd64"; fi && \
    curl -L "https://go.dev/dl/go1.24.2.linux-${GO_ARCH}.tar.gz" | tar -C /usr/local -xz
ENV PATH=$PATH:/usr/local/go/bin

# 5. Bun Runtime
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH=$PATH:/root/.bun/bin

# 6. Terminal IDEs (Micro, Helix, Lazygit)
RUN apt-get install -y micro \
    && ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then HELIX_ARCH="x86_64"; LAZY_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then HELIX_ARCH="aarch64"; LAZY_ARCH="arm64"; \
    fi && \
    curl -L "https://github.com/helix-editor/helix/releases/download/25.01.1/helix-25.01.1-${HELIX_ARCH}-linux.tar.xz" | tar xJ && \
    mv helix-25.01.1-${HELIX_ARCH}-linux/hx /usr/local/bin/ && \
    mkdir -p /root/.config/helix && mv helix-25.01.1-${HELIX_ARCH}-linux/runtime /root/.config/helix/ && \
    rm -rf helix-25.01.1-${HELIX_ARCH}-linux && \
    curl -L "https://github.com/jesseduffield/lazygit/releases/download/v0.61.1/lazygit_0.61.1_Linux_${LAZY_ARCH}.tar.gz" | tar xz lazygit && \
    install lazygit /usr/local/bin

# 7. AI CLIs (Gemini, Codex, RTK)
RUN npm install -g @google/gemini-cli @openai/codex \
    && ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then RTK_ARCH="x86_64-unknown-linux-musl"; \
    elif [ "$ARCH" = "aarch64" ]; then RTK_ARCH="aarch64-unknown-linux-gnu"; \
    fi && \
    curl -L "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-${RTK_ARCH}.tar.gz" | tar xz && \
    install rtk /usr/local/bin/rtk && rm rtk

# 8. UI/UX STACK (1. Fastfetch, 2. Oh-My-Bash, 3. Alias-Hub, 4. Neofetch-ASCII)
RUN add-apt-repository -y ppa:zhangsongcui3371/fastfetch \
    && apt-get update && apt-get install -y fastfetch \
    && bash -c "$(wget -qO- https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended \
    && bash -c "$(wget -qO- https://raw.githubusercontent.com/1999AZZAR/alias-hub/master/install.sh)" || true \
    && git clone https://github.com/1999AZZAR/neofetch_ascii.git /root/.local/share/neofetch_ascii

# 9. SSH Configuration
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo 'root:root' | chpasswd

# 10. MCP Servers
RUN mkdir -p /root/MCPservers \
    && git clone https://github.com/1999AZZAR/terminal-mcp-server.git /root/MCPservers/terminal \
    && cd /root/MCPservers/terminal && npm install && npm run build \
    && git clone https://github.com/1999AZZAR/filesystem-mcp-server.git /root/MCPservers/filesystem \
    && cd /root/MCPservers/filesystem && npm install && npm run build \
    && npm install -g @modelcontextprotocol/server-sequential-thinking \
    && echo '#!/bin/bash\nnode /root/MCPservers/terminal/build/index.js "$@"' > /usr/local/bin/mcp-terminal \
    && echo '#!/bin/bash\nnode /root/MCPservers/filesystem/dist/index.js "$@"' > /usr/local/bin/mcp-filesystem \
    && chmod +x /usr/local/bin/mcp-terminal /usr/local/bin/mcp-filesystem

# 11. Non-Root User & Sudoers Setup
RUN if getent group ${HOST_GID} >/dev/null; then \
        EXISTING_GRP=$(getent group ${HOST_GID} | cut -d: -f1); \
    else \
        groupadd -g ${HOST_GID} ${GHOST_USER}; \
        EXISTING_GRP=${GHOST_USER}; \
    fi && \
    if id -u ${HOST_UID} >/dev/null 2>&1; then \
        EXISTING_USR=$(id -un ${HOST_UID}); \
        usermod -l ${GHOST_USER} -d /home/${GHOST_USER} -m -g ${EXISTING_GRP} ${EXISTING_USR} 2>/dev/null || true; \
    else \
        useradd -u ${HOST_UID} -g ${EXISTING_GRP} -m -s /bin/bash ${GHOST_USER}; \
    fi && \
    mkdir -p /etc/sudoers.d && \
    echo "${GHOST_USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${GHOST_USER} && \
    chmod 0440 /etc/sudoers.d/${GHOST_USER} && \
    echo "${GHOST_USER}:${GHOST_USER}" | chpasswd && \
    mkdir -p /home/${GHOST_USER}/.ssh && \
    chown -R ${GHOST_USER}:${EXISTING_GRP} /home/${GHOST_USER}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

# ==============================================================================
# ROCI GHOST MACHINE - MASTER TEMPLATE (UBUNTU)
# ==============================================================================
# Build: docker build -t ubuntu-template:latest .
# ==============================================================================

FROM ubuntu:latest

# Build Arguments & Versions
ARG GHOST_USER=developer
ARG HOST_UID=1000
ARG HOST_GID=1000
ARG GO_VERSION=1.24.2
ARG HELIX_VERSION=25.01.1
ARG LAZYGIT_VERSION=0.61.1

# 1. Environment & UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# 2. Base System & Build Tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl gnupg git wget unzip software-properties-common sudo ca-certificates \
    build-essential gdb make cmake \
    python3 python-is-python3 python3-pip python3-venv pipx \
    htop btop net-tools glances sysstat inxi ncdu tree \
    zip p7zip-full nmap lsof xclip \
    nnn fzf ripgrep tmux \
    bat eza zoxide fd-find jq \
    kitty kitty-terminfo \
    openssh-server \
    && mkdir -p /var/run/sshd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 3. Node.js (Latest Current)
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 4. Go & Rust Runtimes
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then GO_ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then GO_ARCH="arm64"; else GO_ARCH="amd64"; fi && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" | tar -C /usr/local -xz && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --no-modify-path && \
    cp /root/.cargo/bin/* /usr/local/bin/ 2>/dev/null || true
ENV PATH=$PATH:/usr/local/go/bin:/root/.cargo/bin

# 5. Bun & Python UV Runtimes
RUN curl -fsSL https://bun.sh/install | bash && \
    curl -fsSL https://astral.sh/uv/install.sh | bash && \
    cp /root/.local/bin/uv* /usr/local/bin/ 2>/dev/null || true
ENV PATH=$PATH:/root/.bun/bin:/root/.local/bin

# 6. Terminal IDEs (Micro, Helix, Lazygit)
RUN apt-get update && apt-get install -y --no-install-recommends micro \
    && ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then HELIX_ARCH="x86_64"; LAZY_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then HELIX_ARCH="aarch64"; LAZY_ARCH="arm64"; \
    fi && \
    curl -fsSL "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-${HELIX_ARCH}-linux.tar.xz" | tar xJ && \
    mv helix-${HELIX_VERSION}-${HELIX_ARCH}-linux/hx /usr/local/bin/ && \
    mkdir -p /root/.config/helix && mv helix-${HELIX_VERSION}-${HELIX_ARCH}-linux/runtime /root/.config/helix/ && \
    rm -rf helix-${HELIX_VERSION}-${HELIX_ARCH}-linux && \
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZY_ARCH}.tar.gz" | tar xz lazygit && \
    install lazygit /usr/local/bin && rm -f lazygit \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 7. AI Harness CLIs (Antigravity CLI, OpenCode, Kilo CLI, RTK)
RUN npm install -g @kilocode/cli opencode-ai \
    && ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then RTK_ARCH="x86_64-unknown-linux-musl"; \
    elif [ "$ARCH" = "aarch64" ]; then RTK_ARCH="aarch64-unknown-linux-gnu"; \
    fi && \
    curl -fsSL "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-${RTK_ARCH}.tar.gz" | tar xz && \
    install rtk /usr/local/bin/rtk && rm -f rtk \
    && (curl -fsSL https://antigravity.ai/install.sh | bash 2>/dev/null || true) \
    && if [ -f /root/.local/bin/agy ]; then ln -sf /root/.local/bin/agy /usr/local/bin/agy && ln -sf /root/.local/bin/agy /usr/local/bin/antigravity; fi \
    && npm cache clean --force

# 8. UI/UX STACK (1. Fastfetch, 2. Oh-My-Bash, 3. Alias-Hub, 4. Neofetch-ASCII)
RUN add-apt-repository -y ppa:zhangsongcui3371/fastfetch \
    && apt-get update && apt-get install -y --no-install-recommends fastfetch \
    && bash -c "$(wget -qO- https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended \
    && bash -c "$(wget -qO- https://raw.githubusercontent.com/1999AZZAR/alias-hub/master/install.sh)" || true \
    && git clone --depth=1 https://github.com/1999AZZAR/neofetch_ascii.git /root/.local/share/neofetch_ascii \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 9. SSH Configuration
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo 'root:root' | chpasswd

# 10. HeLa MCP Ecosystem (Profile: headless-server)
RUN git clone --depth=1 https://github.com/1999AZZAR/hela-mcp-ecosystem.git /opt/mcp-ecosystem \
    && cd /opt/mcp-ecosystem \
    && ./setup.sh --profile headless-server --client antigravity --non-interactive \
    && mkdir -p /root/.mcp \
    && node scripts/generate-config.mjs headless-server --backend antigravity --root /opt/mcp-ecosystem --out /root/.mcp/config.json \
    && ln -sf /opt/mcp-ecosystem /root/MCPservers \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/chaining-mcp-server/dist/index.js "$@"' > /usr/local/bin/mcp-mitosis \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/Project-Guardian-mcp-server/dist/index.js "$@"' > /usr/local/bin/mcp-genome \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/filesystem-mcp-server/dist/index.js "$@"' > /usr/local/bin/mcp-membrane \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/terminal-mcp-server/build/index.js "$@"' > /usr/local/bin/mcp-nucleus \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/menager-mcp-server/build/index.js "$@"' > /usr/local/bin/mcp-ribosome \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/research-mcp-server/dist/index.js "$@"' > /usr/local/bin/mcp-enzyme \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/the-designer/dist/index.js "$@"' > /usr/local/bin/mcp-phenotype \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/terminal-mcp-server/build/index.js "$@"' > /usr/local/bin/mcp-terminal \
    && echo '#!/bin/bash\nnode /opt/mcp-ecosystem/filesystem-mcp-server/dist/index.js "$@"' > /usr/local/bin/mcp-filesystem \
    && chmod +x /usr/local/bin/mcp-* \
    && npm cache clean --force

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
    mkdir -p /home/${GHOST_USER}/.ssh /home/${GHOST_USER}/.mcp /home/${GHOST_USER}/.local/bin /home/${GHOST_USER}/.cargo/bin && \
    cp /root/.mcp/config.json /home/${GHOST_USER}/.mcp/config.json 2>/dev/null || true && \
    chown -R ${GHOST_USER}:${EXISTING_GRP} /home/${GHOST_USER}

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

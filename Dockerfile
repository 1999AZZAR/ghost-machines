# ==============================================================================
# ROCI GHOST MACHINE - MASTER TEMPLATE
# ==============================================================================
# Build: docker build -t ubuntu-template:latest .
# ==============================================================================

FROM ubuntu:latest

# 1. Environment & UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# 2. Base System & Build Tools
RUN apt-get update && apt-get install -y \
    curl gnupg git wget unzip software-properties-common \
    build-essential gdb make cmake \
    python3 python-is-python3 python3-pip python3-venv \
    htop net-tools glances sysstat inxi ncdu tree \
    zip p7zip-full nmap lsof xclip \
    openssh-server \
    && mkdir /var/run/sshd

# 3. Node.js (Latest Current)
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs

# 4. Go Runtime
RUN curl -L https://go.dev/dl/go1.24.2.linux-arm64.tar.gz | tar -C /usr/local -xz
ENV PATH=$PATH:/usr/local/go/bin

# 5. Bun Runtime
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH=$PATH:/root/.bun/bin

# 6. Terminal IDEs (Micro, Helix, Lazygit)
RUN apt-get install -y micro \
    && curl -L https://github.com/helix-editor/helix/releases/download/25.01.1/helix-25.01.1-aarch64-linux.tar.xz | tar xJ \
    && mv helix-25.01.1-aarch64-linux/hx /usr/local/bin/ \
    && mkdir -p /root/.config/helix && mv helix-25.01.1-aarch64-linux/runtime /root/.config/helix/ \
    && rm -rf helix-25.01.1-aarch64-linux \
    && curl -L https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_0.48.2_Linux_arm64.tar.gz | tar xz lazygit && install lazygit /usr/local/bin

# 7. AI CLIs (Gemini, Codex)
RUN npm install -g @google/gemini-cli @openai/codex

# 8. UI/UX STACK (1. Fastfetch, 2. Oh-My-Bash, 3. Alias-Hub)
RUN add-apt-repository -y ppa:zhangsongcui3371/fastfetch \
    && apt-get update && apt-get install -y fastfetch \
    && bash -c "$(wget -qO- https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended \
    && bash -c "$(wget -qO- https://raw.githubusercontent.com/1999AZZAR/alias-hub/master/install.sh)" || true

# 9. SSH Configuration
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && echo 'root:root' | chpasswd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]

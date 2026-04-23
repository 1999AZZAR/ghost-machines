# Ghost Machines

Master template and orchestration for custom Ubuntu-based dev environments.

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com1999AZZAR/ghost-machines.git
   cd ghost-machines
   ```

2. **Build the master image:**
   ```bash
   docker build -t ubuntu-template:latest .
   ```

3. **Spin up the machines:**
   ```bash
   docker compose up -d
   ```

## Requirements
- Docker & Docker Compose
- LXCFS (optional, for accurate resource reporting in `/proc`)
  - If you don't have LXCFS, you can comment out the volume mounts for `/proc/` in `docker-compose.yml`.

## Configuration
- **SSH:** Access containers via ports `2223` (ubuntu1) and `2224` (ubuntu2).
- **Credentials:** Default `root:root`.
- **Mounts:** Local `./mounts/ubuntu1` and `./mounts/ubuntu2` are mapped to `/home/ubuntu` in the respective containers.

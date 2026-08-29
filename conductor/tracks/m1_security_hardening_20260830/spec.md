# Specification: M1 Security Hardening & Host-Container Permission Isolation

## Overview
This track implements security hardening, host UID/GID synchronization, non-root user execution, SSH public key injection, and pre-flight validation for credentials and tunnels in Ghost Machines.

## Functional Requirements
1. **Host UID/GID Detection & Mapping:**
   - In `start.sh`, automatically detect host `UID` (`id -u`) and `GID` (`id -g`), with optional `.env` overrides (`HOST_UID`, `HOST_GID`).
   - Pass `UID` and `GID` build args or runtime environment variables to Docker Compose and Dockerfiles so container file ownership matches host ownership in persistent `mounts/`.
2. **Dedicated Non-Root User (`ghost` / `developer`):**
   - Ensure a non-root developer user with sudo privileges (`sudo` without password) exists in all container images with matching UID/GID.
   - Default environment and toolchain paths configured for the developer user as well as root.
3. **SSH Authentication Hardening & Key Injection:**
   - Support mounting host SSH public keys (`~/.ssh/id_rsa.pub`, `~/.ssh/id_ed25519.pub`, or `~/.ssh/authorized_keys`) into the container's `.ssh/authorized_keys`.
   - Provide configurable `SSH_PASSWORD_AUTH` toggle (default: `false` when SSH key is present, configurable in `.env`).
4. **Secrets & Pre-flight Checks:**
   - Ensure secure file permissions (`chmod 600`) on `.env` if present.
   - Add pre-flight validation of `TUNNEL_TOKEN` format to avoid silent tunnel startup failures.

## Acceptance Criteria
- Running `start.sh` creates mounts with file ownership matching the host UID/GID (no `root:root` locked files on host).
- SSH key authentication works seamlessly when host keys are present.
- SSH password authentication can be safely toggled off.
- Pre-flight checks give actionable error messages for misconfigured `.env` or invalid tunnel tokens.

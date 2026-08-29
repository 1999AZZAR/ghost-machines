# Product Guidelines

## Core Principles
1. **Reproducibility & Idempotency:** Any environment built from the repository must result in an identical, operational state regardless of the host machine.
2. **Resource Consciousness:** Minimize image footprint and background CPU/RAM churn. Container startup scripts must be fast, resilient, and non-blocking.
3. **Ergonomic Developer Experience:** Out-of-the-box shell completions, syntax highlighting, alias hubs, and modern CLI tools configured for immediate productivity.
4. **Defensive Scripting:** All orchestration and setup scripts must enforce robust error handling, exit traps, architecture sanity checks, and clear diagnostic messages.
5. **Security & Least Privilege:** Provide secure defaults, warn against hardcoded credentials in persistent mounts, and isolate host namespaces safely.

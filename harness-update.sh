#!/usr/bin/env bash
# ==============================================================================
# GHOST MACHINES — BUILT-IN AI HARNESS REFRESHER (NO PINNED VERSIONS)
# ==============================================================================
# Installs whatever upstream publishes as "latest" right now:
#   opencode -> https://opencode.ai/v2/install
#   agy      -> https://antigravity.google/cli/install.sh (also linked as antigravity)
#   rtk      -> https://github.com/rtk-ai/rtk/releases/latest/download
#
# Usage:
#   harness-update                 Refresh every harness
#   harness-update opencode rtk    Refresh a subset (opencode|agy|rtk|all)
#   harness-update --if-due        Refresh only when the stamp is stale
#   harness-update --no-stamp      Refresh without recording the stamp
#   harness-update --interval 6    Staleness window in hours (default 24)
#   harness-update --quiet         Suppress output (entrypoint usage)
#
# Environment:
#   HARNESS_BIN_DIR               Target directory (default: /usr/local/bin)
#   HARNESS_STAMP                 Stamp file (default: /var/lib/ghost/harness-update.stamp)
#   HARNESS_UPDATE_INTERVAL_HOURS Staleness window (default: 24)
#
# Exit codes:
#   0  every requested harness is current, or nothing was due
#   1  every requested harness failed to update
#   2  partial success (some updated, some failed/skipped)
# ==============================================================================

set -uo pipefail

BIN_DIR="${HARNESS_BIN_DIR:-/usr/local/bin}"
STAMP="${HARNESS_STAMP:-/var/lib/ghost/harness-update.stamp}"
INTERVAL_HOURS="${HARNESS_UPDATE_INTERVAL_HOURS:-24}"

IF_DUE=false
RECORD_STAMP=true
QUIET=false
TARGETS=()

UPDATED=0
SKIPPED=0
FAILED=0

say() { [ "$QUIET" = true ] || printf '%s\n' "$*"; }
warn() { [ "$QUIET" = true ] || printf '[SKIP] %s\n' "$*" >&2; }
fail() { [ "$QUIET" = true ] || printf '[FAIL] %s\n' "$*" >&2; }

die() {
    fail "$*"
    exit 1
}

usage() {
    cat <<'EOF'
Ghost Machines — refresh built-in AI harnesses to their latest upstream release.

Usage: harness-update [harness...] [options]

Harnesses: opencode | agy | rtk | all   (default: all)

Options:
  --if-due              Update only when the stamp is older than the interval
  --no-stamp            Update without recording the stamp
  --interval <hours>    Staleness window for --if-due (default: 24)
  -q, --quiet           Suppress output
  -h, --help            Show this help

Environment:
  HARNESS_BIN_DIR               install target      (/usr/local/bin)
  HARNESS_STAMP                 stamp file          (/var/lib/ghost/harness-update.stamp)
  HARNESS_UPDATE_INTERVAL_HOURS staleness window    (24)
EOF
}

# --- Argument parsing ---------------------------------------------------------
while [ "$#" -gt 0 ]; do
    case "$1" in
        --if-due) IF_DUE=true ;;
        --no-stamp) RECORD_STAMP=false ;;
        --quiet|-q) QUIET=true ;;
        --interval)
            [ -n "${2:-}" ] || die "--interval requires a value"
            INTERVAL_HOURS="$2"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        opencode|agy|rtk) TARGETS+=("$1") ;;
        all) TARGETS+=(opencode agy rtk) ;;
        *) die "Unknown argument: $1 (expected opencode|agy|rtk|all)" ;;
    esac
    shift
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
    TARGETS=(opencode agy rtk)
fi

case "$INTERVAL_HOURS" in
    ''|*[!0-9]*) die "--interval must be a whole number of hours" ;;
esac

# --- Privilege handling -------------------------------------------------------
# Escalate once, up front, so the stamp, lock and binary writes all agree.
if [ "$(id -u)" -ne 0 ] && [ ! -w "$BIN_DIR" ]; then
    command -v sudo >/dev/null 2>&1 || die "root or sudo is required to write into $BIN_DIR"
    exec sudo -E "$0" "$@"
fi

# --- Serialise concurrent refreshes -------------------------------------------
# A directory lock, not flock: utilit-linux flock and BusyBox flock have
# incompatible option sets (BusyBox has no -w), and Alpine ships BusyBox.
LOCK_DIR="${HARNESS_LOCK:-${STAMP}.lock}"
LOCK_WAIT="${HARNESS_LOCK_WAIT:-900}"        # seconds to wait for a peer
LOCK_STALE="${HARNESS_LOCK_STALE:-1800}"     # seconds before a lock is abandoned
LOCK_HELD=false

# Single cleanup path: a failed run must not wedge the lock or leak the temp dir.
trap 'if [ "$LOCK_HELD" = true ]; then rmdir "$LOCK_DIR" 2>/dev/null || true; fi; if [ -n "${TMP_ROOT:-}" ]; then rm -rf "$TMP_ROOT"; fi' EXIT

acquire_lock() {
    local parent waited=0 age
    parent=$(dirname "$LOCK_DIR")
    if ! mkdir -p "$parent" 2>/dev/null || [ ! -w "$parent" ]; then
        return 0    # cannot serialise here; proceed rather than hang
    fi
    # Migrate a leftover lock file from older versions.
    if [ -f "$LOCK_DIR" ]; then
        rm -f "$LOCK_DIR" 2>/dev/null || true
    fi
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        age=$(( $(date +%s) - $(stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0) ))
        if [ "$age" -gt "$LOCK_STALE" ]; then
            rm -rf "$LOCK_DIR" 2>/dev/null || true
            continue
        fi
        sleep 2
        waited=$((waited + 2))
        if [ "$waited" -ge "$LOCK_WAIT" ]; then
            die "another harness-update is still running (lock: $LOCK_DIR)"
        fi
    done
    LOCK_HELD=true
}

acquire_lock

PRIV=()
run() {
    if [ "${#PRIV[@]}" -eq 0 ]; then
        "$@"
    else
        "${PRIV[@]}" "$@"
    fi
}

# --- Staleness stamp ----------------------------------------------------------
stamp_due() {
    [ -f "$STAMP" ] || return 0
    local last now
    last=$(stat -c %Y "$STAMP" 2>/dev/null || echo 0)
    [ "${last:-0}" -gt 0 ] || return 0
    now=$(date +%s)
    [ $(( (now - last) / 3600 )) -ge "$INTERVAL_HOURS" ]
}

write_stamp() {
    run mkdir -p "$(dirname "$STAMP")" 2>/dev/null || true
    printf '%s\n' "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" | run tee "$STAMP" >/dev/null 2>&1 || true
}

if [ "$IF_DUE" = true ] && ! stamp_due; then
    say "[OK] Harnesses refreshed less than ${INTERVAL_HOURS}h ago, skipping."
    exit 0
fi

# --- Helpers ------------------------------------------------------------------
TMP_ROOT="$(mktemp -d)"

# fetch_script <url> <home> <log> [installer args...]
fetch_script() {
    local url="$1" home="$2" log="$3"
    shift 3
    curl -fsSL --retry 2 --connect-timeout 10 --max-time 300 "$url" 2>>"$log" \
        | HOME="$home" bash -s -- "$@" >>"$log" 2>&1
}

# put_binary <source> <name> — installs into BIN_DIR, never through a symlink
put_binary() {
    local src="$1" name="$2"
    if [ -L "$BIN_DIR/$name" ]; then
        warn "$name is host-managed (symlink), skipped"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    if [ -e "$BIN_DIR/$name" ] && ! ( : >> "$BIN_DIR/$name" ) 2>/dev/null; then
        warn "$name is a read-only bind mount, skipped"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi
    if ! run install -m 0755 "$src" "$BIN_DIR/$name"; then
        fail "$name: cannot write $BIN_DIR/$name"
        FAILED=$((FAILED + 1))
        return 0
    fi
    UPDATED=$((UPDATED + 1))
}

# --- Harness updaters ---------------------------------------------------------
update_opencode() {
    local home="$TMP_ROOT/opencode" log="$TMP_ROOT/opencode.log"
    mkdir -p "$home"
    if ! fetch_script https://opencode.ai/v2/install "$home" "$log" --no-modify-path; then
        fail "opencode: installer failed (${log})"
        FAILED=$((FAILED + 1))
        return 0
    fi
    if [ ! -x "$home/.opencode/bin/opencode" ]; then
        fail "opencode: binary not produced by installer"
        FAILED=$((FAILED + 1))
        return 0
    fi
    put_binary "$home/.opencode/bin/opencode" opencode
}

update_agy() {
    local home="$TMP_ROOT/agy" log="$TMP_ROOT/agy.log"
    mkdir -p "$home"
    if ! fetch_script https://antigravity.google/cli/install.sh "$home" "$log" --dir "$home/.local/bin"; then
        fail "agy: installer failed (${log})"
        FAILED=$((FAILED + 1))
        return 0
    fi
    if [ ! -x "$home/.local/bin/agy" ]; then
        fail "agy: binary not produced by installer"
        FAILED=$((FAILED + 1))
        return 0
    fi
    put_binary "$home/.local/bin/agy" agy
}

update_rtk() {
    local log="$TMP_ROOT/rtk.log" arch
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch="aarch64-unknown-linux-gnu" ;;
        *) fail "rtk: unsupported architecture $(uname -m)"; FAILED=$((FAILED + 1)); return 0 ;;
    esac
    if ! curl -fsSL --retry 2 --connect-timeout 10 --max-time 300 \
            "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-${arch}.tar.gz" \
            2>>"$log" | tar xz -C "$TMP_ROOT" >>"$log" 2>&1; then
        fail "rtk: download failed (${log})"
        FAILED=$((FAILED + 1))
        return 0
    fi
    put_binary "$TMP_ROOT/rtk" rtk
}

# --- Run ----------------------------------------------------------------------
for TARGET in "${TARGETS[@]}"; do
    case "$TARGET" in
        opencode) update_opencode ;;
        agy) update_agy ;;
        rtk) update_rtk ;;
    esac
done

# Keep the agy/antigravity aliases in sync with whatever binary is now in place
if [ -x "$BIN_DIR/agy" ] && [ ! -L "$BIN_DIR/agy" ]; then
    run ln -sfn "$BIN_DIR/agy" "$BIN_DIR/antigravity" 2>/dev/null || true
fi

if [ "$RECORD_STAMP" = true ] && [ "$UPDATED" -gt 0 ]; then
    write_stamp
fi

if [ "$QUIET" = false ] && [ "$UPDATED" -gt 0 ]; then
    say "[OK] Harness binaries resolved to latest:"
    for BIN in opencode agy rtk; do
        [ -x "$BIN_DIR/$BIN" ] || continue
        VERSION=$(timeout 20 "$BIN_DIR/$BIN" --version 2>/dev/null | head -n 1 | tr -d '\r')
        printf '  %-9s %s\n' "$BIN" "${VERSION:-unknown}"
    done
fi

if [ "$FAILED" -gt 0 ] && [ "$UPDATED" -eq 0 ]; then
    exit 1
fi
if [ "$FAILED" -gt 0 ] || [ "$SKIPPED" -gt 0 ]; then
    exit 2
fi
exit 0

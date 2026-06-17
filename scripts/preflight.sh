#!/bin/sh

set -eu

failures=0
DOCKER_CMD=${DOCKER:-docker}

pass() {
    printf '[PASS] %s\n' "$1"
}

warn() {
    printf '[WARN] %s\n' "$1"
}

fail() {
    printf '[FAIL] %s\n' "$1"
    failures=$((failures + 1))
}

if [ "$(uname -m)" = "x86_64" ]; then
    pass "CPU architecture is x86_64"
else
    fail "CPU architecture is $(uname -m); linuxserver/msedge requires x86_64"
fi

if grep -qw avx2 /proc/cpuinfo; then
    pass "CPU supports AVX2"
else
    fail "AVX2 is unavailable; the Wayland stack may not run"
fi

docker_bin=${DOCKER_CMD%% *}
if command -v "$docker_bin" >/dev/null 2>&1; then
    pass "Docker CLI is installed"
else
    fail "Docker CLI is not installed or not found: $docker_bin"
fi

if $DOCKER_CMD info >/dev/null 2>&1; then
    pass "Docker daemon is reachable using: $DOCKER_CMD"
else
    fail "Docker daemon is not reachable using: $DOCKER_CMD"
    if [ "$DOCKER_CMD" = "docker" ]; then
        warn "This only means the current user cannot access Docker directly."
        warn "On fnOS, retry with: DOCKER=\"sudo docker\" ./scripts/preflight.sh"
    fi
fi

if $DOCKER_CMD compose version >/dev/null 2>&1; then
    pass "Docker Compose plugin is available"
else
    fail "Docker Compose plugin is unavailable"
fi

if [ -d /dev/dri ]; then
    pass "/dev/dri exists"
    ls -l /dev/dri
else
    fail "/dev/dri is missing; AMD GPU acceleration cannot be enabled"
fi

render_node="${DRI_RENDER_NODE:-/dev/dri/renderD128}"
if [ -e "$render_node" ]; then
    pass "Render node exists: $render_node"
else
    fail "Render node does not exist: $render_node"
fi

if [ -r "$render_node" ] && [ -w "$render_node" ]; then
    pass "Current user can access $render_node"
else
    warn "Current user cannot read/write $render_node; Docker may still access it"
fi

if [ -f .env ]; then
    pass ".env exists"
    edge_password="$(sed -n 's/^EDGE_PASSWORD=//p' .env | head -n 1)"
    if [ "$edge_password" = "change-me-before-start" ]; then
        fail "EDGE_PASSWORD still uses the example value"
    elif [ "${#edge_password}" -lt 12 ]; then
        fail "EDGE_PASSWORD must contain at least 12 characters"
    else
        pass "EDGE_PASSWORD is not the example value"
    fi
else
    fail ".env is missing; copy .env.example and edit it first"
fi

if [ "$failures" -ne 0 ]; then
    printf '\nPreflight failed with %s blocking issue(s).\n' "$failures"
    exit 1
fi

printf '\nPreflight passed.\n'

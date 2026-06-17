#!/bin/sh

set -eu

container="${CONTAINER_NAME:-fnos-edge-phase1}"
DOCKER_CMD=${DOCKER:-docker}

if ! $DOCKER_CMD inspect "$container" >/dev/null 2>&1; then
    printf '[FAIL] Container does not exist: %s\n' "$container"
    printf '[INFO] If Docker needs sudo on this NAS, retry: DOCKER="sudo docker" ./scripts/verify.sh\n'
    exit 1
fi

status="$($DOCKER_CMD inspect --format '{{.State.Status}}' "$container")"
if [ "$status" != "running" ]; then
    printf '[FAIL] Container status is %s\n' "$status"
    $DOCKER_CMD logs --tail 100 "$container"
    exit 1
fi
printf '[PASS] Container is running\n'

restart_count="$($DOCKER_CMD inspect --format '{{.RestartCount}}' "$container")"
printf '[INFO] Restart count: %s\n' "$restart_count"

printf '[INFO] GPU devices visible in container:\n'
$DOCKER_CMD exec "$container" sh -c 'ls -l /dev/dri 2>/dev/null || true'

printf '[INFO] Recent GPU and Wayland log lines:\n'
$DOCKER_CMD logs "$container" 2>&1 |
    grep -Ei 'wayland|renderD|vaapi|gpu|zero.?copy|pixel' |
    tail -n 80 || true

printf '\nOpen https://NAS_IP:%s and complete the manual checklist in docs/NAS_TEST.md.\n' \
    "${EDGE_HTTPS_PORT:-3443}"

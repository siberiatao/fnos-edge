#!/bin/sh

set -eu

startup_url="${EDGE_STARTUP_URL:-https://www.bing.com}"
window_size="${EDGE_WINDOW_SIZE:-1600,900}"
window_position="${EDGE_WINDOW_POSITION:-40,40}"
launcher="/config/start-edge.sh"

cat > "$launcher" <<'EOF'
#!/bin/sh

set -eu

startup_url="${EDGE_STARTUP_URL:-https://www.bing.com}"
window_size="${EDGE_WINDOW_SIZE:-1600,900}"
window_position="${EDGE_WINDOW_POSITION:-40,40}"

if pgrep -f 'microsoft-edge|msedge' >/dev/null 2>&1; then
    exit 0
fi

edge_bin=""
for candidate in microsoft-edge microsoft-edge-stable msedge; do
    if command -v "$candidate" >/dev/null 2>&1; then
        edge_bin="$candidate"
        break
    fi
done

if [ -z "$edge_bin" ]; then
    echo "[edge-autostart] Microsoft Edge binary not found" >&2
    exit 1
fi

exec "$edge_bin" \
    --no-first-run \
    --disable-session-crashed-bubble \
    --disable-features=Translate \
    --window-size="$window_size" \
    --window-position="$window_position" \
    "$startup_url"
EOF

chmod +x "$launcher"

mkdir -p /config/.config/labwc /config/.config/openbox

cat > /config/.config/labwc/autostart <<EOF
EDGE_STARTUP_URL="${startup_url}" EDGE_WINDOW_SIZE="${window_size}" EDGE_WINDOW_POSITION="${window_position}" ${launcher} &
EOF

cat > /config/.config/openbox/autostart <<EOF
EDGE_STARTUP_URL="${startup_url}" EDGE_WINDOW_SIZE="${window_size}" EDGE_WINDOW_POSITION="${window_position}" ${launcher} &
EOF

echo "[edge-autostart] Autostart configured for ${startup_url}, window ${window_size} at ${window_position}"

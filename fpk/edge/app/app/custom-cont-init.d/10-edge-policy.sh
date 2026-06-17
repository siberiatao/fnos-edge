#!/bin/sh

set -eu

policy_dir="/etc/opt/edge/policies/managed"
policy_file="${policy_dir}/fnos-edge.json"
startup_url="${EDGE_STARTUP_URL:-https://www.bing.com}"

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

escaped_startup_url="$(json_escape "$startup_url")"

mkdir -p "$policy_dir"
cat > "$policy_file" <<EOF
{
  "HideFirstRunExperience": true,
  "PromotionalTabsEnabled": false,
  "RestoreOnStartup": 4,
  "RestoreOnStartupURLs": [
    "${escaped_startup_url}"
  ],
  "HomepageIsNewTabPage": false,
  "HomepageLocation": "${escaped_startup_url}"
}
EOF

echo "[edge-policy] Managed Edge startup policy written to ${policy_file}"

#!/bin/sh

set -eu

app_dir="${1:-fpk/edge}"
dist_dir="${2:-dist}"

if [ ! -f "$app_dir/manifest" ]; then
    echo "Missing manifest under $app_dir" >&2
    exit 1
fi

mkdir -p "$dist_dir"

appname="$(sed -n 's/^appname=//p' "$app_dir/manifest" | head -n 1)"
version="$(sed -n 's/^version=//p' "$app_dir/manifest" | head -n 1)"

if [ -z "$appname" ] || [ -z "$version" ]; then
    echo "manifest must contain appname and version" >&2
    exit 1
fi

out="$dist_dir/${appname}-${version}.fpk"
tmp_dir="${TMPDIR:-/tmp}/${appname}-fpk-build-$$"

rm -rf "$tmp_dir"
mkdir -p "$tmp_dir/package"

if [ ! -d "$app_dir/app" ]; then
    echo "Missing app payload directory: $app_dir/app" >&2
    exit 1
fi

# fnOS expects the runtime payload to be stored as app.tgz. The archive is
# extracted into TRIM_APPDEST, so its root must contain docker/, ui/, etc.
tar --exclude '.DS_Store' -czf "$tmp_dir/package/app.tgz" -C "$app_dir/app" .

for path in manifest ICON.PNG ICON_256.PNG cmd config wizard; do
    if [ -e "$app_dir/$path" ]; then
        cp -R "$app_dir/$path" "$tmp_dir/package/$path"
    fi
done

tar --exclude '.DS_Store' -czf "$out" -C "$tmp_dir/package" .
rm -rf "$tmp_dir"
echo "$out"

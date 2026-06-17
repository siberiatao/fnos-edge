#!/bin/sh

set -eu

out_dir="${1:-fpk/edge}"
tmp_dir="${TMPDIR:-/tmp}/edge-icons"
mkdir -p "$out_dir/app/ui/images" "$tmp_dir"
svg_source="${SVG_SOURCE:-assets/edge.svg}"
node_bin="${NODE_BIN:-/Users/siberiatao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node}"
node_modules="${NODE_MODULES:-/Users/siberiatao/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules}"

render_svg_with_sharp() {
    size="$1"
    out="$2"

    [ -x "$node_bin" ] || return 1
    [ -d "$node_modules" ] || return 1
    [ -f "$svg_source" ] || return 1

    NODE_PATH="$node_modules" "$node_bin" - "$svg_source" "$out" "$size" <<'JS'
const fs = require("fs");
const sharp = require("sharp");

const [svgPath, outPath, sizeText] = process.argv.slice(2);
const size = Number(sizeText);

sharp(fs.readFileSync(svgPath), { density: 300, limitInputPixels: false })
  .resize(size, size, { fit: "contain", background: { r: 0, g: 0, b: 0, alpha: 0 } })
  .png()
  .toFile(outPath)
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
JS
}

render_svg_with_quicklook() {
    size="$1"
    out="$2"
    work="$tmp_dir/ql-$size"

    command -v qlmanage >/dev/null 2>&1 || return 1
    [ -f "$svg_source" ] || return 1

    rm -rf "$work"
    mkdir -p "$work"
    qlmanage -t -s "$size" -o "$work" "$svg_source" >/dev/null 2>&1 || return 1

    rendered="$(find "$work" -type f -name '*.png' | head -n 1)"
    [ -n "$rendered" ] || return 1
    cp "$rendered" "$out"
}

generate_png() {
    size="$1"
    out="$2"
    python3 - "$size" "$out" <<'PY'
import math
import struct
import sys
import zlib

size = int(sys.argv[1])
out = sys.argv[2]
scale = size / 256.0
cx = cy = size * 0.50
icon_r = size * 0.345
hole_r = size * 0.115
soft = max(1.0, size * 0.025)

def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return int(a + (b - a) * t)

def over(dst, src):
    sr, sg, sb, sa = src
    dr, dg, db, da = dst
    a = sa + da * (255 - sa) // 255
    if a == 0:
        return (0, 0, 0, 0)
    r = (sr * sa + dr * da * (255 - sa) // 255) // a
    g = (sg * sa + dg * da * (255 - sa) // 255) // a
    b = (sb * sa + db * da * (255 - sa) // 255) // a
    return (r, g, b, a)

def rounded_rect_coverage(x, y, left, top, right, bottom, radius):
    qx = abs(x - (left + right) / 2.0) - (right - left) / 2.0 + radius
    qy = abs(y - (top + bottom) / 2.0) - (bottom - top) / 2.0 + radius
    ox = max(qx, 0.0)
    oy = max(qy, 0.0)
    dist = math.hypot(ox, oy) + min(max(qx, qy), 0.0) - radius
    return max(0.0, min(1.0, 0.5 - dist))

def circle_alpha(dist, radius, feather):
    return max(0.0, min(1.0, (radius - dist) / feather + 0.5))

def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xffffffff)

rows = []
for y in range(size):
    row = bytearray([0])
    for x in range(size):
        px = x + 0.5
        py = y + 0.5
        color = (0, 0, 0, 0)

        # Soft drop shadow.
        shadow = rounded_rect_coverage(
            px,
            py,
            27 * scale,
            31 * scale,
            229 * scale,
            233 * scale,
            34 * scale,
        )
        if shadow > 0:
            color = over(color, (24, 31, 45, int(50 * shadow)))

        # White rounded tile matching fnOS launcher style.
        tile = rounded_rect_coverage(
            px,
            py,
            24 * scale,
            24 * scale,
            232 * scale,
            232 * scale,
            34 * scale,
        )
        if tile > 0:
            color = over(color, (246, 249, 253, int(255 * tile)))

        dx = x - cx
        dy = y - cy
        dist = math.hypot(dx, dy)
        angle = (math.atan2(dy, dx) + math.pi * 2.0) % (math.pi * 2.0)
        theta = angle / (math.pi * 2.0)

        # Base circular swirl.
        outer = circle_alpha(dist, icon_r, soft)
        inner_cut = circle_alpha(dist, hole_r, soft)
        ring_alpha = max(0.0, outer * (1.0 - inner_cut * 0.55))
        if ring_alpha > 0:
            if theta < 0.28:
                t = theta / 0.28
                swirl = (mix(0, 26, t), mix(188, 117, t), mix(226, 235, t))
            elif theta < 0.58:
                t = (theta - 0.28) / 0.30
                swirl = (mix(26, 31, t), mix(117, 210, t), mix(235, 160, t))
            elif theta < 0.82:
                t = (theta - 0.58) / 0.24
                swirl = (mix(31, 63, t), mix(210, 224, t), mix(160, 113, t))
            else:
                t = (theta - 0.82) / 0.18
                swirl = (mix(63, 0, t), mix(224, 188, t), mix(113, 226, t))
            color = over(color, (*swirl, int(255 * ring_alpha)))

        # Blue inner crescent.
        c2x = cx + size * 0.045
        c2y = cy + size * 0.040
        d2 = math.hypot(x - c2x, y - c2y)
        crescent_outer = circle_alpha(d2, size * 0.205, soft)
        crescent_inner = circle_alpha(math.hypot(x - (cx - size * 0.02), y - (cy - size * 0.015)), size * 0.135, soft)
        crescent = crescent_outer * (1.0 - crescent_inner * 0.75)
        if crescent > 0:
            color = over(color, (8, 126, 222, int(235 * crescent)))

        # Green sweep at lower left, approximating Edge's wave.
        wave_center_x = cx - size * 0.030
        wave_center_y = cy + size * 0.055
        wave_d = math.hypot(x - wave_center_x, y - wave_center_y)
        wave = circle_alpha(wave_d, size * 0.235, soft) * (1.0 - circle_alpha(dist, hole_r * 0.95, soft))
        if y < cy + size * 0.02:
            wave *= max(0.0, (y - (cy - size * 0.18)) / (size * 0.20))
        if wave > 0:
            color = over(color, (15, 207, 145, int(230 * wave)))

        # Light center cut.
        center = circle_alpha(dist, size * 0.095, soft)
        if center > 0:
            color = over(color, (244, 249, 253, int(255 * center)))

        row.extend(color)
    rows.append(bytes(row))

with open(out, "wb") as f:
    f.write(b"\x89PNG\r\n\x1a\n")
    f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)))
    f.write(chunk(b"IDAT", zlib.compress(b"".join(rows), 9)))
    f.write(chunk(b"IEND", b""))
PY
}

render_svg_with_sharp 64 "$out_dir/ICON.PNG" || render_svg_with_quicklook 64 "$out_dir/ICON.PNG" || generate_png 64 "$out_dir/ICON.PNG"
render_svg_with_sharp 256 "$out_dir/ICON_256.PNG" || render_svg_with_quicklook 256 "$out_dir/ICON_256.PNG" || generate_png 256 "$out_dir/ICON_256.PNG"
cp "$out_dir/ICON.PNG" "$out_dir/app/ui/images/icon_64.png"
cp "$out_dir/ICON_256.PNG" "$out_dir/app/ui/images/icon_256.png"

echo "Generated icons in $out_dir"

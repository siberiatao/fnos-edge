# Phase 2 FPK Packaging

Phase 2 wraps the validated Edge Compose prototype as an fnOS Docker
application.

## Source Layout

```text
fpk/edge/
├── manifest
├── ICON.PNG
├── ICON_256.PNG
├── app/
│   ├── docker/docker-compose.yaml
│   └── ui/config
├── cmd/
├── config/
└── wizard/install
```

## Build Locally

```bash
./scripts/generate_icons.sh
./scripts/build_fpk.sh
```

The package is written to:

```text
dist/edge-0.8.0.fpk
```

## Install On fnOS

1. Open fnOS App Center developer/manual install flow.
2. Upload `dist/edge-0.8.0.fpk`.
3. Use these first-test values:
   - container HTTPS port: `3443`
   - image: `lscr.io/linuxserver/msedge:latest`
   - PUID/PGID: `1000` / `1001` on your NAS test host
   - startup URL: `https://www.bing.com`
   - GPU node: `/dev/dri/renderD128`
   - CPU limit: `4`
   - memory limit: `4g`
4. Start the app and open it from the fnOS desktop.

## Acceptance

- App Center can install the package.
- Docker project is created by fnOS.
- Container starts and exposes HTTPS on the configured port.
- FN Connect opens a generated subdomain entry, similar to
  `https://edge.YOUR_FNOS_CONNECT_DOMAIN/`.
- Direct HTTP fallback access opens `http://YOUR_DOMAIN_OR_IP:3002/`.
- Direct HTTPS fallback access opens `https://YOUR_DOMAIN_OR_IP:3443/`.
- Edge profile persists after app restart.
- `/var/apps/edge/shares/data/config` contains Edge profile data.
- `/var/apps/edge/shares/downloads` is available for file transfer.

## Known Follow-Ups

- Confirm whether fnOS automatically registers Docker app path proxy from the
  app metadata, or whether another resource field is needed.
- Replace the generated placeholder icon only after checking trademark rules.
- Add an upgrade path for future LinuxServer image version bumps.

The default image is `lscr.io/linuxserver/msedge:latest` for easier browser
updates. If a future image breaks WebSocket/audio/input/file transfer, pin it
back to the validated tag `lscr.io/linuxserver/msedge:149.0.4022.69-1-ls173`.

Version `0.7.0` registered the app with the fnOS unified gateway using
`gatewayPrefix=/app/edge` and `gatewaySocket=edge.sock`. A lightweight nginx
sidecar listens on `/var/apps/edge/target/edge.sock` and proxies HTTP/WebSocket
traffic to the Edge container on `https://msedge:3001`, so FN Connect can use
the system gateway instead of the standalone HTTPS port.

## Cleanup During Development

Current versions use only the `edge` app/container/share names. Earlier test
packages used `edge-browser` and `docker-edge-browser`; remove those manually
only after confirming they are no longer installed.

```bash
sudo docker rm -f edge-browser docker-edge-browser 2>/dev/null || true
sudo rm -rf /var/apps/edge-browser /var/apps/docker-edge-browser
```

If Edge shows `WebSocket disconnected` and logs repeat `Wayland mode: Waiting
for socket`, clear stale runtime sockets and restart the app:

```bash
sudo docker rm -f edge 2>/dev/null || true
sudo rm -rf /var/apps/edge/shares/data/config/.XDG
sudo rm -rf /var/apps/edge/shares/data/config/.cache/labwc
```

Version `0.6.0` kept the validated PUID/PGID fix and restored `/edge/` plus
the `latest` image default.

Version `0.6.1` adds a managed Edge policy to skip first-run pages and force a
stable startup URL, reducing occasional black-screen startup sessions.

Version `0.6.2` also writes a desktop autostart script so Microsoft Edge opens
automatically instead of requiring the launcher icon to be clicked manually.

Version `0.7.0` changes the stable entry path to `/app/edge/` so fnOS unified
gateway and FN Connect can route the app without exposing the standalone port.

Version `0.7.1` keeps the unified gateway registration but restores the desktop
entry type to `url`, matching the official Chromium app behavior of opening in
a browser tab instead of embedding inside the fnOS desktop iframe.

Version `0.7.2` makes Edge startup more assertive: it waits for the desktop,
always opens a new Edge window instead of skipping when background processes
exist, and tries to activate the visible Edge window.

Version `0.7.3` adds a persistent in-container autolaunch watcher and tunes the
default stream for FN Connect: 1080p, 30 FPS, CRF 30, `AUTO_GPU=true`, and
`seccomp:unconfined` for better GUI/GPU compatibility.

Version `0.7.4` rolls back the startup watcher and all display/stream tuning,
leaving only the unified gateway changes for focused validation.

Version `0.7.5` adds back only `MAX_RES=1920x1080` to cap the remote desktop
canvas and avoid oversized Selkies viewports, without restoring startup watcher
or stream tuning changes.

Version `0.7.6` keeps the unified gateway socket but changes the public prefix
back from `/app/edge/` to `/edge/`, matching the previous Edge baseline and the
official Chromium app's root-level path style.

Version `0.7.7` restores the fnOS gateway public route to `/app/edge/` after
testing showed root-level `/edge/` is not registered by the unified gateway.

Version `0.7.8` adds an optional direct HTTP fallback port mapped to container
port `3000`, while keeping the HTTPS fallback on `3001` and the fnOS unified
gateway route unchanged.

Version `0.8.0` switches from path-based unified gateway mode to the same
port-type URL app style used by the official 1Panel package: `protocol=http`
and `port=3002` in `ui/config`. The container serves Edge from the root path,
so FN Connect can generate a subdomain-style entry and direct access no longer
needs `/app/edge/`.

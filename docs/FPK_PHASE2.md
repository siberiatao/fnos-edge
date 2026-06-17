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
dist/edge-0.6.2.fpk
```

## Install On fnOS

1. Open fnOS App Center developer/manual install flow.
2. Upload `dist/edge-0.6.2.fpk`.
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
- Direct access opens `https://YOUR_DOMAIN_OR_IP:3443/edge/`.
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

The current stable package uses the Edge container's HTTPS port directly with
`SUBFOLDER=/edge/`. fnOS gateway port `5667` was tested separately, but the
direct app port is the validated baseline.

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

Version `0.6.0` keeps the validated PUID/PGID fix and restores `/edge/` plus
the `latest` image default.

Version `0.6.1` adds a managed Edge policy to skip first-run pages and force a
stable startup URL, reducing occasional black-screen startup sessions.

Version `0.6.2` also writes a desktop autostart script so Microsoft Edge opens
automatically instead of requiring the launcher icon to be clicked manually.

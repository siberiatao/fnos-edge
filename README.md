# fnOS Edge

Microsoft Edge for fnOS, delivered through a browser-accessible Docker
container and ultimately packaged as an fnOS FPK application.

## Current Status

Phase 1 validated the Docker Edge runtime on an AMD Ryzen 7 7840HS NAS running
fnOS 1.1.3107.

Follow [docs/NAS_TEST.md](docs/NAS_TEST.md) on the NAS.

Phase 2 adds an fnOS FPK-style application source tree under
`fpk/edge` and a locally generated package:

```text
dist/edge-0.8.0.fpk
```

Follow [docs/FPK_PHASE2.md](docs/FPK_PHASE2.md) for package testing.

## Baseline

- App name: `edge`
- Display name: `Edge`
- Image: `lscr.io/linuxserver/msedge:latest`
- Default FN Connect access: `https://edge.<fnOS-connect-domain>/`
- Direct HTTP fallback access: `http://<fnOS-host>:3002/`
- Direct HTTPS fallback access: `https://<fnOS-host>:3443/`
- Default runtime user: `PUID=1000`, `PGID=1001`
- Default remote desktop max resolution: `1920x1080`

## Roadmap

1. Validate Edge, HTTPS, persistence, AMD GPU acceleration, audio, clipboard,
   input, and file transfer on the target NAS.
2. Wrap the validated Compose project in an fnOS FPK application.
3. Test App Center installation and desktop launch.
4. Integrate safer fnOS access, certificates, upgrades, and data retention.

# Phase 1 NAS Test

This phase validates the upstream Edge container before it is wrapped as an
fnOS FPK application.

## What Codex prepared

- A version-pinned Microsoft Edge container.
- Persistent Edge profile storage under `data/config`.
- HTTPS-only host exposure.
- AMD GPU passthrough with Wayland and explicit render/encode nodes.
- Basic authentication and hardened desktop defaults.
- Preflight and post-start diagnostic scripts.

## What you do on the NAS

### 1. Put the project on the NAS

Copy or clone this directory to a normal NAS data directory, then enter it:

```bash
cd /path/to/fei_app
```

Do not place the phase 1 project under `/var/apps`; fnOS owns that location.

### 2. Create the local configuration

```bash
cp .env.example .env
id
```

Edit `.env`:

- Set `PUID` and `PGID` from the `id` output.
- Replace `EDGE_USERNAME`.
- Replace `EDGE_PASSWORD` with a strong password.
- Change `EDGE_HTTPS_PORT` if `3443` is already occupied.

Create the persistent directory:

```bash
mkdir -p data/config
```

### 3. Run the preflight check

fnOS commonly requires `sudo docker` for shell users. Use sudo-backed Docker for
this phase:

```bash
chmod +x scripts/*.sh
DOCKER="sudo docker" ./scripts/preflight.sh
```

Running `./scripts/preflight.sh` without `DOCKER="sudo docker"` is only useful
to check whether your current shell user can access Docker directly. It is fine
for that mode to fail on fnOS.

Send the complete output back to Codex if the sudo-backed preflight fails.

### 4. Validate and start

```bash
sudo docker compose config | sed 's/PASSWORD: .*/PASSWORD: REDACTED/'
sudo docker compose pull
sudo docker compose up -d
sudo docker compose ps
DOCKER="sudo docker" ./scripts/verify.sh
```

The image is large, so the first pull can take a while.

### 5. Open Edge

Visit:

```text
https://NAS_IP:3443
```

Use the actual port from `.env`. The browser will initially warn about the
container's self-signed certificate. This is expected only for phase 1.

## Manual acceptance checklist

Report each item as pass or fail:

- Login prompt accepts the configured username and password.
- Edge reaches its initial page.
- Refreshing the page reconnects to the same session.
- After `docker compose restart`, Edge settings and login state remain.
- Chinese text can be typed into a web page.
- Text can be copied between the local browser and remote Edge.
- Audio from a test video reaches the local computer.
- A file can be uploaded into remote Edge.
- A file can be downloaded from remote Edge.
- 1920x1080 display remains responsive for ten minutes.
- `docker stats fnos-edge-phase1` shows acceptable CPU and memory usage.
- `./scripts/verify.sh` contains Wayland/GPU-related output.

Do not test this service over the public Internet during phase 1.

## Useful diagnostics

```bash
sudo docker compose ps
sudo docker logs --tail 200 fnos-edge-phase1
sudo docker stats --no-stream fnos-edge-phase1
ls -l /dev/dri
```

## Stop or reset

Stop without deleting the Edge profile:

```bash
sudo docker compose down
```

Remove the test profile only when a clean reset is intentionally required:

```bash
sudo docker compose down
rm -rf data/config
```

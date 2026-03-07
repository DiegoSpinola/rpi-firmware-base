# CLAUDE.md

## Project Overview

**rpi-firmware-base** is a generic base Docker image for Raspberry Pi applications. It provides a minimal Debian Bookworm runtime with hardware access utilities. Downstream images add application-specific stacks on top.

Related: [gstreamer-tofsrc#29](https://github.com/caema-solutions/gstreamer-tofsrc/issues/29)

## Architecture

Layered image design:

```
App image (e.g. tofsrc, serial-logger, etc.)
  |
  FROM middleware image (e.g. gstreamer + libcamera)
  |
  FROM rpi-firmware-base:latest    <-- this repo
  |
  Debian Bookworm slim (aarch64)
```

The base image is intentionally minimal. It includes only system utilities common to any Pi application (udev, usbutils, i2c-tools, kmod, curl). All domain-specific packages belong in downstream images.

## Project Structure

```
rpi-firmware-base/
├── Dockerfile          # Base image definition
├── docker-compose.yml  # Build orchestration + image naming
├── .config             # Alloy dependencies + deployable service
├── alloy.sh            # Alloy environment launcher (host-side)
├── build.sh            # Build image
├── deploy.sh           # Push to registry
├── run.sh              # Run service (not usable on x86 build host — arm64 only)
├── .gitignore
├── CLAUDE.md           # This file
└── README.md
```

## Alloy Framework

- **`alloy.sh`** — Run on host to enter the Alloy container
- **`build.sh`** — Builds Docker image, tags with git commit hash (or `WIP` if dirty)
- **`deploy.sh`** — Pushes to `push.igmify.com` registry (requires VPN)
- **`run.sh`** — Starts service via docker-compose. Cannot run on x86 build host since the image targets arm64.

All scripts except `alloy.sh` require the Alloy environment (`$CUSTOM_HOSTNAME == "alloy"`).

### Image naming

```
push.igmify.com/rpi-firmware-base/rpi-firmware-base:${COMMIT_HASH}
```

## Key Decisions

- **Minimal base** — Only system utilities. No GStreamer, no libcamera, no application frameworks.
- **arm64 only** — Targets Raspberry Pi. `run.sh` will not work on x86 build hosts.
- **Privileged runtime** — Containers need `--privileged` or `--device` flags for hardware access.
- **Template scripts unchanged** — `build.sh`, `deploy.sh`, `run.sh`, `alloy.sh` follow the standard Alloy template pattern.

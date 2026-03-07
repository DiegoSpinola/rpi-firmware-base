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

The base image is intentionally minimal. It includes system utilities common to any Pi application (udev, usbutils, i2c-tools, kmod, curl) plus Pi-specific tools (vcgencmd, pinctrl via `raspberrypi-utils`). All domain-specific packages belong in downstream images.

A built-in `self-test` command verifies peripheral access (CPU temp, throttling, GPIO, I2C, SPI, serial, USB, video, kernel modules).

## Project Structure

```
rpi-firmware-base/
├── Dockerfile          # Base image definition
├── self-test.sh        # Peripheral self-test (baked into image as `self-test`)
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

- **Minimal base** — System utilities + Pi-specific tools. No GStreamer, no libcamera, no application frameworks.
- **RPi apt repo included** — `raspberrypi-utils` (vcgencmd, pinctrl) requires the RPi apt repo.
- **Built-in self-test** — `self-test` command baked into the image for verifying peripheral access.
- **arm64 only** — Targets Raspberry Pi. `run.sh` will not work on x86 build hosts.
- **Privileged runtime** — Containers need `--privileged` or `--device` flags for hardware access.
- **Template scripts unchanged** — `build.sh`, `deploy.sh`, `run.sh`, `alloy.sh` follow the standard Alloy template pattern.

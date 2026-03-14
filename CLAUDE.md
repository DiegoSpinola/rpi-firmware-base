# CLAUDE.md

## Project Overview

**rpi-firmware-base** is a generic base Docker image for Raspberry Pi applications. It provides a minimal Debian runtime with hardware access utilities. Downstream images add application-specific stacks on top.

## Architecture

Layered image design:

```
App image (e.g. gantry-jig, serial-logger, etc.)
  |
  FROM rpi-firmware-base:<variant>-<arch>-latest
  |
  Debian Bookworm or Trixie slim
```

The base image is intentionally minimal: system utilities (udev, usbutils, i2c-tools, kmod, curl) plus Pi-specific tools (vcgencmd, pinctrl). All domain-specific packages belong in downstream images.

A built-in `self-test` command verifies peripheral access (CPU temp, throttling, GPIO, I2C, SPI, serial, USB, video, kernel modules).

## Image Variants

Four variants from two Dockerfiles across two architectures:

| Variant | Base | Pi utils package | Arch | Target |
|---------|------|-----------------|------|--------|
| `bookworm-arm64` | `debian:bookworm-slim` | `libraspberrypi-bin` | aarch64 | Pi 4, Pi 5 |
| `trixie-arm64` | `debian:trixie-slim` | `raspi-utils-core` | aarch64 | Pi 4, Pi 5 |
| `bookworm-armv7` | `debian:bookworm-slim` | `libraspberrypi-bin` | armhf | Pi 2, Pi 3, Pi Zero W |
| `trixie-armv7` | `debian:trixie-slim` | `raspi-utils-core` | armhf | Pi 2, Pi 3, Pi Zero W |

### Package naming across Debian versions

The Pi utilities package has different names per Debian release:
- **Bookworm (Debian 12):** `libraspberrypi-bin`
- **Trixie (Debian 13):** `raspi-utils-core`
- Note: `raspberrypi-utils` (mentioned in some docs) does NOT exist in either arm64 repo

### Trixie SHA1 signing workaround

The RPi apt repo signs its trixie InRelease with a SHA1 key, which Debian Trixie's `sqv` rejects since 2026-02-01. `Dockerfile.trixie` uses `[trusted=yes]` as a workaround. See [harus-hw-env issue #9](https://github.com/igma-company/harus-hw-env/issues/9) — remove once RPi re-signs with SHA256+.

## Image naming

```
push.igmify.com/rpi-firmware-base/rpi-firmware-base:<variant>-<arch>-<hash>
push.igmify.com/rpi-firmware-base/rpi-firmware-base:<variant>-<arch>-latest
```

Examples:
```
push.igmify.com/rpi-firmware-base/rpi-firmware-base:bookworm-armv7-f2068dd
push.igmify.com/rpi-firmware-base/rpi-firmware-base:bookworm-armv7-latest
```

## Project Structure

```
rpi-firmware-base/
├── Dockerfile.bookworm   # Bookworm variant (libraspberrypi-bin)
├── Dockerfile.trixie     # Trixie variant (raspi-utils-core, trusted=yes workaround)
├── self-test.sh          # Peripheral self-test (baked into image as `self-test`)
├── docker-compose.yml    # Build orchestration (all 4 variants)
├── .config               # Alloy config + all 4 services as deployable
├── alloy.sh              # Alloy environment launcher
├── build.sh              # Native build (docker-compose v1)
├── deploy.sh             # Native build + push
├── xbuild.sh             # Cross-compile build (docker compose v2 + QEMU)
├── xdeploy.sh            # Cross-compile build + push
├── run.sh                # Run service (arm only — won't work on x86 without QEMU)
├── CLAUDE.md             # This file
└── README.md
```

## Cross-compilation

Building arm images on x86 requires:

1. **Docker Compose v2** — `sudo apt-get install docker-compose-v2`
2. **QEMU binfmt** — `docker run --privileged --rm tonistiigi/binfmt --install arm64,arm`

Use `xbuild.sh` / `xdeploy.sh` instead of `build.sh` / `deploy.sh`. The `x` variants use `docker compose` (v2) which supports cross-platform builds via QEMU.

## Alloy Framework

- **`alloy.sh`** — Run on host to enter the Alloy container
- **`build.sh`** / **`xbuild.sh`** — Build Docker images, tag with git commit hash (or `WIP` if dirty)
- **`deploy.sh`** / **`xdeploy.sh`** — Push to `push.igmify.com` registry (requires VPN)
- **`run.sh`** — Starts service via docker-compose (arm only)

All scripts except `alloy.sh` require the Alloy environment (`$CUSTOM_HOSTNAME == "alloy"`).

## Key Decisions

- **Minimal base** — System utilities + Pi-specific tools only. No Python, no app frameworks.
- **Two Dockerfiles** — Bookworm and Trixie have different package names for Pi utils
- **Four variants** — arm64 (Pi 4/5) and armv7 (Pi 2/3/Zero) for each Debian version
- **`trusted=yes` for trixie** — Temporary workaround for RPi repo SHA1 signing issue
- **`xbuild.sh`/`xdeploy.sh`** — Separate scripts for cross-compilation (docker compose v2) vs native (docker-compose v1)
- **Latest tag fix** — deploy scripts replace commit hash with `latest` (not strip-and-append) to preserve variant prefix in tag

## Downstream Images

Known downstream images using this base:
- **rd-hw-xyz-gantry-jig** — XYZ gantry daemon (Python + pyserial, armv7)

## Docker install on Trixie Pi

Docker doesn't publish a trixie repo for Raspbian. Install using the bookworm repo:

```bash
# Clean any stale docker repo entries
sudo rm -f /etc/apt/sources.list.d/docker.list
# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/raspbian/gpg -o /etc/apt/keyrings/docker.asc
# Add bookworm repo (not trixie — Docker doesn't have it yet)
echo "deb [arch=armhf signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/raspbian bookworm stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

Note: the `get.docker.com` convenience script reads `lsb_release --codename` which returns `trixie` even if `/etc/os-release` is patched. Manual install is the only reliable approach.

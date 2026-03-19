# rpi-firmware-base

Generic base Docker image for Raspberry Pi applications. Provides a minimal Debian runtime with hardware access utilities that downstream images can specialize.

## Image Variants

Four variants are built from two Dockerfiles across two architectures:

| Variant | Base | Pi utilities package | Arch | Tag format | Target |
|---------|------|---------------------|------|------------|--------|
| **Bookworm arm64** | `debian:bookworm-slim` | `libraspberrypi-bin` | aarch64 | `bookworm-arm64-<hash>` | Pi 4, Pi 5 |
| **Trixie arm64** | `debian:trixie-slim` | `raspi-utils-core` | aarch64 | `trixie-arm64-<hash>` | Pi 4, Pi 5 |
| **Bookworm armv7** | `debian:bookworm-slim` | `libraspberrypi-bin` | armhf | `bookworm-armv7-<hash>` | Pi 2, Pi 3, Pi Zero W |
| **Trixie armv7** | `debian:trixie-slim` | `raspi-utils-core` | armhf | `trixie-armv7-<hash>` | Pi 2, Pi 3, Pi Zero W |

All variants include: curl, udev, usbutils, i2c-tools, kmod, vcgencmd, pinctrl, and a built-in `self-test` command.

> **Note (Trixie):** The RPi apt repo signs its trixie InRelease with a SHA1 key, which Debian Trixie's `sqv` rejects since 2026-02-01. The trixie Dockerfile uses `[trusted=yes]` as a workaround. See [issue #9](https://github.com/igma-company/harus-hw-env/issues/9) — remove once RPi re-signs with SHA256+.

## Usage

Downstream images reference a variant as their base:

```dockerfile
FROM registry.hackeneering.com/hackeneering/rpi-firmware-base:bookworm-arm64-latest

# Add your application stack
RUN apt-get update && apt-get install -y ...
COPY entrypoint.sh /app/
ENTRYPOINT ["/app/entrypoint.sh"]
```

### Example downstream images

- GStreamer + libcamera layer (for camera applications)
- Serial/USB device communication (e.g. gantry daemon)
- Sensor logging (I2C, SPI, GPIO)

## Development

### Prerequisites

- Docker (with Docker Compose v2 plugin for cross-compilation)
- [Alloy framework](https://github.com/igma-company/alloy)

### Build (native, on a Pi)

```bash
./alloy.sh
bash build.sh
```

### Cross-compilation (x86 host building arm64 images)

Building arm64 images on an x86 host requires QEMU user-mode emulation and Docker Compose v2.

#### 1. Install Docker Compose v2

The legacy `docker-compose` (v1, Python) does not support cross-platform builds. Docker Compose v2 (Go plugin) does.

```bash
# Ubuntu/Debian
sudo apt-get install docker-compose-v2

# Verify
docker compose version
# Should show v2.x
```

#### 2. Register QEMU binfmt for arm64

This lets Docker run arm64 and armv7 binaries inside containers on an x86 host:

```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64,arm
```

This only needs to be done once per host boot. Verify:

```bash
docker run --rm --platform linux/arm64 debian:bookworm-slim uname -m
# Should output: aarch64
```

#### 3. Build with xbuild.sh

```bash
./alloy.sh
bash xbuild.sh
```

`xbuild.sh` is identical to `build.sh` but uses `docker compose` (v2) instead of `docker-compose` (v1). It builds all four variants in parallel.

Output images:
```
registry.hackeneering.com/hackeneering/rpi-firmware-base:bookworm-arm64-<hash>
registry.hackeneering.com/hackeneering/rpi-firmware-base:trixie-arm64-<hash>
registry.hackeneering.com/hackeneering/rpi-firmware-base:bookworm-armv7-<hash>
registry.hackeneering.com/hackeneering/rpi-firmware-base:trixie-armv7-<hash>
```

(Tag is `WIP` if the git tree is dirty.)

### Deploy

```bash
# Push to registry (requires VPN)
bash deploy.sh
```

### Self-test

Once the container is running on a Pi, verify peripheral access:

```bash
docker exec <container> self-test
```

Checks CPU temp, throttling, firmware, GPIO, I2C, SPI, serial, USB, video devices, and kernel modules.

## Project Structure

```
rpi-firmware-base/
├── Dockerfile.bookworm  # Bookworm variant (libraspberrypi-bin)
├── Dockerfile.trixie    # Trixie variant (raspi-utils-core, trusted=yes workaround)
├── self-test.sh         # Peripheral self-test (baked into image as `self-test`)
├── docker-compose.yml   # Build orchestration (both variants)
├── .config              # Alloy configuration + deployable services
├── alloy.sh             # Start Alloy environment
├── build.sh             # Build image (native, docker-compose v1)
├── xbuild.sh            # Build image (cross-compile, docker compose v2)
├── deploy.sh            # Push to registry
├── run.sh               # Run service (arm64 only — see note below)
└── README.md
```

> **Note**: `run.sh` uses `docker-compose up` which starts the container on the build server. Since images target arm64, this will not work on an x86 host without QEMU. Use `run.sh` on a Pi or after setting up QEMU (see cross-compilation above).

## Running on a Raspberry Pi

### 1. Install Docker

Docker is a prerequisite on every target Pi. The official convenience script installs `docker-ce`, `docker-ce-cli`, `containerd.io`, and `docker-compose-plugin`. It does **not** upgrade existing packages — safe to run alongside fragile stacks (Arducam, libcamera, etc.).

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in for group change to take effect
```

Verify:

```bash
docker run --rm hello-world
```

### 2. Pull and run

```bash
# Pull the bookworm image
docker pull registry.hackeneering.com/hackeneering/rpi-firmware-base:bookworm-arm64-latest

# Run with hardware access
docker run --rm --privileged \
    registry.hackeneering.com/hackeneering/rpi-firmware-base:bookworm-arm64-latest \
    self-test
```

### 3. Run interactively

```bash
docker run -it --privileged \
    registry.hackeneering.com/hackeneering/rpi-firmware-base:bookworm-arm64-latest \
    bash
```

### 4. Portainer (optional — remote management)

```bash
docker run -d -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
```

Access Portainer at `https://<pi-ip>:9443`. From there you can deploy stacks, pull new images, and manage containers via web UI.

### Runtime requirements

- **`--privileged`** (or specific `--device` flags for the hardware you need)
- **`network_mode: host`** if the application needs network services (e.g. RTSP)
- Relevant kernel modules loaded on the host

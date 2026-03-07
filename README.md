# rpi-firmware-base

Generic base Docker image for Raspberry Pi applications. Provides a minimal Debian runtime with hardware access utilities that downstream images can specialize.

## What's included

- **Debian Bookworm slim** (aarch64)
- **Pi utilities**: vcgencmd, pinctrl (from RPi apt repo via `raspberrypi-utils`)
- **System utilities**: curl, udev, usbutils, i2c-tools, kmod
- **Built-in self-test**: `self-test` command to verify peripheral access

## Usage

Downstream images reference this as their base:

```dockerfile
FROM push.igmify.com/rpi-firmware-base/rpi-firmware-base:latest

# Add your application stack
RUN apt-get update && apt-get install -y ...
COPY entrypoint.sh /app/
ENTRYPOINT ["/app/entrypoint.sh"]
```

### Example downstream images

- GStreamer + libcamera layer (for camera applications)
- Serial/USB device communication
- Sensor logging (I2C, SPI, GPIO)

## Development

### Prerequisites

- Docker
- [Alloy framework](https://github.com/igma-company/alloy)

### Build

```bash
# Start Alloy environment
./alloy.sh

# Build the image
bash build.sh
```

### Deploy

```bash
# Push to registry (requires VPN)
bash deploy.sh
```

### Run

> **Note**: `run.sh` uses `docker-compose up` which starts the container on the build server. Since this image targets arm64 (Raspberry Pi), it cannot run natively on an x86 build host. For now, `run.sh` is kept as-is from the template but will not work until run on an arm64 host or via QEMU emulation.

### Self-test

Once the container is running on a Pi, verify peripheral access:

```bash
docker exec <container> self-test
```

Checks CPU temp, throttling, firmware, GPIO, I2C, SPI, serial, USB, video devices, and kernel modules.

## Project Structure

```
rpi-firmware-base/
├── Dockerfile          # Base image definition (aarch64)
├── self-test.sh        # Peripheral self-test (baked into image as `self-test`)
├── docker-compose.yml  # Build orchestration
├── .config             # Alloy configuration
├── alloy.sh            # Start Alloy environment
├── build.sh            # Build image
├── deploy.sh           # Push to registry
├── run.sh              # Run service (see note above)
└── README.md
```

## Running on a Raspberry Pi

### 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in for group change to take effect
```

### 2. Pull and run

```bash
# Pull the base image
docker pull push.igmify.com/rpi-firmware-base/rpi-firmware-base:latest

# Run with hardware access
docker run --rm --privileged \
    push.igmify.com/rpi-firmware-base/rpi-firmware-base:latest \
    self-test
```

### 3. Run interactively

```bash
docker run -it --privileged \
    push.igmify.com/rpi-firmware-base/rpi-firmware-base:latest \
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

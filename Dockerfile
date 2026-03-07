FROM debian:bookworm-slim

ARG COMMIT_HASH=unknown
LABEL org.opencontainers.image.revision="${COMMIT_HASH}"
LABEL org.opencontainers.image.description="Raspberry Pi firmware base image"

# Add Raspberry Pi apt repository (for vcgencmd, pinctrl, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates gnupg curl \
    && curl -fsSL https://archive.raspberrypi.com/debian/raspberrypi.gpg.key \
        | gpg --dearmor -o /usr/share/keyrings/raspberrypi-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/raspberrypi-archive-keyring.gpg] http://archive.raspberrypi.com/debian/ bookworm main" \
        > /etc/apt/sources.list.d/raspi.list \
    && apt-get update

# System utilities + Pi-specific tools
RUN apt-get install -y --no-install-recommends \
        udev \
        usbutils \
        i2c-tools \
        kmod \
        raspberrypi-utils \
    && rm -rf /var/lib/apt/lists/*

# Self-test script
COPY self-test.sh /usr/local/bin/self-test
RUN chmod +x /usr/local/bin/self-test

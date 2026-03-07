FROM debian:bookworm-slim

ARG COMMIT_HASH=unknown
LABEL org.opencontainers.image.revision="${COMMIT_HASH}"
LABEL org.opencontainers.image.description="Raspberry Pi firmware base image"

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        udev \
        usbutils \
        i2c-tools \
        kmod \
    && rm -rf /var/lib/apt/lists/*

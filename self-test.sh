#!/bin/bash
# Self-test script for rpi-firmware-base
# Verifies that Pi peripherals are accessible from inside the container.
# Run with: self-test

PASS=0
FAIL=0
WARN=0

pass() { echo "  [OK]   $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
warn() { echo "  [WARN] $1"; ((WARN++)); }
skip() { echo "  [SKIP] $1"; }

echo "=== Raspberry Pi Firmware Base — Self Test ==="
echo ""

# --- CPU & Thermal ---
echo "--- CPU & Thermal ---"

if command -v vcgencmd &>/dev/null; then
    temp=$(vcgencmd measure_temp 2>&1)
    if [[ $? -eq 0 ]]; then
        pass "CPU temperature: $temp"
    else
        fail "vcgencmd measure_temp: $temp"
    fi

    throttled=$(vcgencmd get_throttled 2>&1)
    if [[ $? -eq 0 ]]; then
        if [[ "$throttled" == "throttled=0x0" ]]; then
            pass "Throttle status: clean (no throttling)"
        else
            warn "Throttle status: $throttled"
        fi
    else
        fail "vcgencmd get_throttled: $throttled"
    fi

    fw=$(vcgencmd version 2>&1 | head -1)
    if [[ $? -eq 0 ]]; then
        pass "Firmware: $fw"
    else
        fail "vcgencmd version: $fw"
    fi
else
    fail "vcgencmd not found"
fi

echo ""

# --- GPIO ---
echo "--- GPIO ---"

gpio_chips=$(ls /dev/gpiochip* 2>/dev/null)
if [[ -n "$gpio_chips" ]]; then
    for chip in $gpio_chips; do
        pass "GPIO chip: $chip"
    done
else
    fail "No /dev/gpiochip* devices found"
fi

if command -v pinctrl &>/dev/null; then
    pass "pinctrl available"
else
    warn "pinctrl not found"
fi

echo ""

# --- I2C ---
echo "--- I2C ---"

i2c_buses=$(i2cdetect -l 2>/dev/null)
if [[ -n "$i2c_buses" ]]; then
    while IFS= read -r line; do
        pass "I2C: $line"
    done <<< "$i2c_buses"
else
    warn "No I2C buses detected (is i2c enabled?)"
fi

echo ""

# --- SPI ---
echo "--- SPI ---"

spi_devs=$(ls /dev/spidev* 2>/dev/null)
if [[ -n "$spi_devs" ]]; then
    for dev in $spi_devs; do
        pass "SPI: $dev"
    done
else
    skip "No /dev/spidev* devices (SPI may not be enabled)"
fi

echo ""

# --- Serial / UART ---
echo "--- Serial / UART ---"

serial_devs=$(ls /dev/ttyAMA* /dev/ttyS* /dev/serial* 2>/dev/null | sort -u)
if [[ -n "$serial_devs" ]]; then
    for dev in $serial_devs; do
        pass "Serial: $dev"
    done
else
    skip "No serial devices found (UART may not be enabled)"
fi

echo ""

# --- USB ---
echo "--- USB ---"

if command -v lsusb &>/dev/null; then
    usb_count=$(lsusb 2>/dev/null | wc -l)
    if [[ $usb_count -gt 0 ]]; then
        pass "USB: $usb_count device(s) found"
        lsusb 2>/dev/null | while IFS= read -r line; do
            echo "         $line"
        done
    else
        warn "USB: lsusb returned no devices"
    fi
else
    fail "lsusb not found"
fi

echo ""

# --- Video / Camera ---
echo "--- Video / Camera ---"

video_devs=$(ls /dev/video* 2>/dev/null)
if [[ -n "$video_devs" ]]; then
    for dev in $video_devs; do
        pass "Video: $dev"
    done
else
    skip "No /dev/video* devices"
fi

media_devs=$(ls /dev/media* 2>/dev/null)
if [[ -n "$media_devs" ]]; then
    for dev in $media_devs; do
        pass "Media: $dev"
    done
else
    skip "No /dev/media* devices"
fi

echo ""

# --- Kernel Modules ---
echo "--- Kernel Modules ---"

if [[ -f /proc/modules ]]; then
    mod_count=$(wc -l < /proc/modules)
    pass "Kernel modules visible: $mod_count loaded"
else
    fail "/proc/modules not accessible"
fi

echo ""

# --- Summary ---
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Warnings: $WARN"
echo "  Failed: $FAIL"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Some checks failed. Ensure the container runs with --privileged"
    echo "and required kernel modules are loaded on the host."
    exit 1
fi

exit 0

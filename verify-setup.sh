#!/usr/bin/env bash
set -euo pipefail

echo "=== Edge AI Lab - Jetson Setup Verification ==="
echo

echo "## Hostname and IP"
hostname
hostname -I || true
echo

echo "## Jetson model"
cat /proc/device-tree/model 2>/dev/null || echo "Could not read Jetson model"
echo

echo "## L4T / JetPack information"
if [ -f /etc/nv_tegra_release ]; then
    cat /etc/nv_tegra_release
else
    echo "/etc/nv_tegra_release not found"
fi
echo

echo "## Disk layout"
lsblk
echo

echo "## Memory and swap"
free -h
swapon --show || true
echo

echo "## Docker"
if command -v docker >/dev/null 2>&1; then
    docker --version
    systemctl is-active docker || true
    docker info 2>/dev/null | grep -E "Runtimes|Default Runtime" || true
else
    echo "Docker is not installed"
fi
echo

echo "## NVIDIA container runtime"
if command -v nvidia-ctk >/dev/null 2>&1; then
    nvidia-ctk --version || true
else
    echo "nvidia-ctk not found"
fi
echo

echo "## CUDA-related device files"
ls /dev/nv* 2>/dev/null || echo "No /dev/nv* devices found"
echo

echo "=== Verification complete ==="

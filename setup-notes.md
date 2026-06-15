# AI Lab 00 — Setup

I will document my Jetson Orin Nano setup process here. The goal of this phase is to create a clean, reproducible base environment for future Edge AI experiments.

## Hardware setup

First, I had some hardware-related issues.

The first problem happened while installing the NVMe SSD. The screw for the 2280 NVMe slot was very hard to remove. In my case, I had to use a correctly fitting Phillips screwdriver, PH2/PH02, to remove it without damaging the screw head.

After installing the NVMe, I had problems during the flashing process because the host machine was not properly detecting the drive. In my case, the NVMe was not being recognized correctly by the flashing workflow. Preparing the drive with a visible partition table and formatting it as `ext4` made it appear correctly, and after that I was able to flash it properly.

To flash the Jetson, I decided to use NVIDIA SDK Manager instead of flashing directly from WSL, because I was using a Windows machine and the WSL flashing process can be tricky. The flashing process through SDK Manager was straightforward.

## First access and networking

After flashing, the next step is software setup.

Jetson devices from the Orin family usually expose a USB-C device-mode network connection. When this works, the Jetson can be accessed through SSH using the default IP address:

```bash
192.168.55.1
```

Example:

```bash
ssh <user>@192.168.55.1
```

If this method does not work, connect the Jetson through Ethernet or configure it on a Wi-Fi network.

I usually flash the device with an already-created user account, so I did not need to manually configure SSH from scratch.

Useful commands:

```bash
hostname -I
```

List available Wi-Fi networks:

```bash
nmcli device wifi list
```

Connect to a Wi-Fi network:

```bash
nmcli device wifi connect <ssid> password <password>
```

## Setting up SSH for GitHub

Generate an SSH key:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Start the SSH agent:

```bash
eval "$(ssh-agent -s)"
```

Add the private key to the agent:

```bash
ssh-add ~/.ssh/id_ed25519
```

Print the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the output and add it to your GitHub account.

## AI Assistance for Jetson

NVIDIA provides AI skills that can be used both on the Jetson device and on the host machine. These skills are useful for getting more targeted assistance with NVIDIA Jetson hardware, Jetson Linux, BSP customization, memory analysis, Docker setup, and related workflows.

For Jetson device-side assistance:

```bash
git clone https://github.com/NVIDIA-AI-IOT/jetson-device-skills.git
cd jetson-device-skills
bash ./install.sh
```

Then restart your AI coding agents, such as Claude Code or Codex.

For host-side BSP assistance:

```bash
git clone https://github.com/NVIDIA-AI-IOT/jetson-bsp-skills.git
cd jetson-bsp-skills
bash ./setup.sh --workspace <workspace_path>
```

The difference is:

```text
jetson-device-skills → used on a running Jetson device
jetson-bsp-skills    → used on the host machine for BSP and flashing-related workflows
```

## Docker setup

Before installing Docker, it is important to understand why Docker matters on Jetson devices.

Docker is a platform for developing, shipping, and running applications. Its main idea is to package an application and its dependencies into a lightweight, portable environment called a container.

A container is not a full virtual machine. It does not include its own Linux kernel. Instead, it shares the host Linux kernel while running with its own isolated filesystem, process tree, networking, environment variables, and dependencies. A Docker image may contain an Ubuntu-like or Debian-like user space, but the actual kernel and hardware drivers still come from the host system.

This distinction is especially important on Jetson devices. Docker can run containers by itself, but it does not automatically give those containers access to Jetson-specific hardware resources such as the GPU, CUDA, TensorRT, NVIDIA libraries, and device files.

To give containers access to these resources, we need the NVIDIA container runtime. The NVIDIA container runtime integrates with Docker and allows containers to access the Jetson GPU stack correctly.

Docker’s default low-level runtime is usually `runc`. For GPU-enabled containers on Jetson, we configure Docker to use the NVIDIA runtime.

### Install Docker and NVIDIA container support

```bash
sudo apt update
sudo apt install -y nvidia-container curl jq

curl -fsSL https://get.docker.com | sh
sudo systemctl --now enable docker

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Set the NVIDIA runtime as Docker’s default runtime

First, make sure Docker’s daemon configuration file exists:

```bash
sudo sh -c 'test -f /etc/docker/daemon.json || echo "{}" > /etc/docker/daemon.json'
```

Then set the NVIDIA runtime as the default:

```bash
sudo jq '. + {"default-runtime": "nvidia"}' /etc/docker/daemon.json | \
  sudo tee /etc/docker/daemon.json.tmp > /dev/null && \
  sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json

sudo systemctl restart docker
```

### Allow the current user to run Docker without sudo

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

This adds the current user to the `docker` group, so Docker commands can be executed without `sudo`.

### Verify Docker runtime configuration

```bash
docker info | grep -E "Runtimes|Default Runtime"
```

Expected idea:

```text
Runtimes: ... nvidia runc ...
Default Runtime: nvidia
```

### Test GPU access inside a container

Run a Jetson-compatible NVIDIA container:

```bash
docker run --rm -it \
  -v "$PWD":/workspace \
  -w /workspace \
  nvcr.io/nvidia/pytorch:25.08-py3
```

Inside the container, test CUDA access from PyTorch:

```bash
python3 <<'EOF'
import torch

print("PyTorch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU name:", torch.cuda.get_device_name(0))
EOF
```

If `torch.cuda.is_available()` returns `True`, Docker and the NVIDIA runtime are working correctly.

## Resource optimization

If you are using a Jetson for AI-powered applications, especially a Jetson Orin Nano with limited resources, it is important to optimize the system to improve performance and reduce unnecessary memory usage.

Jetson devices are based on an SoC, or System on a Chip. This means the main compute system is integrated into one main chip. The SoC contains components such as CPU cores, GPU, memory controllers, PCIe controllers, USB controllers, video/media engines, camera/display interfaces, and security/boot logic.

This does not mean the entire Jetson device is only one chip. The Jetson module also has memory chips and supporting electronics, and the developer kit includes a carrier board with ports, connectors, power circuitry, and other components.

One important detail is that Jetson devices use a unified memory architecture. The CPU and GPU access the same physical system memory. This is different from a desktop PC with a discrete GPU, where the GPU usually has its own separate VRAM.

Because of this, memory pressure matters a lot on Jetson. The operating system, desktop environment, containers, camera buffers, CUDA workloads, TensorRT engines, and application processes all compete for the same memory pool.

### Disable the desktop GUI

If the Jetson will be used headlessly, disabling the desktop GUI can free memory and reduce background resource usage.

Check the current default target:

```bash
systemctl get-default
```

Set the system to boot into headless/multi-user mode:

```bash
sudo systemctl set-default multi-user.target
sudo reboot
```

To switch back to graphical mode:

```bash
sudo systemctl set-default graphical.target
sudo reboot
```

If you want to switch to headless mode immediately, you can use:

```bash
sudo systemctl isolate multi-user.target
```

Only run this if SSH or another remote access method is already working, because it may close the graphical session.

For additional optimization, the Jetson AI skill `jetson-headless-mode` can help identify and disable extra services. The `jetson-memory-audit` skill can be used before and after changes to measure the impact.

## Adding swap memory

Adding swap can help avoid out-of-memory errors. This is especially useful on a Jetson Orin Nano when using large containers, AI models, compilation workloads, or memory-heavy Python packages.

However, swap is not a performance optimization. It is a safety net. If the system is actively swapping a lot during inference, performance will drop significantly. The goal is to prevent crashes, not to make memory-heavy workloads fast.

First, check whether swap is already configured:

```bash
swapon --show
free -h
```

Jetson systems may already have ZRAM-based swap enabled. ZRAM is compressed RAM used as swap. In most cases, it is better to keep ZRAM enabled and add an SSD-backed swap file only as an additional safety net.

Create an 8 GB swap file on the NVMe SSD:

```bash
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Verify:

```bash
swapon --show
free -h
```

To make the swap file persistent after reboot, add this line to the end of `/etc/fstab`:

```bash
/swapfile none swap sw,pri=10 0 0
```

A lower priority helps keep this SSD-backed swap as a fallback instead of replacing faster ZRAM swap.

Only disable `nvzramconfig` if you intentionally want to replace ZRAM with a disk-backed swap strategy. For most lab setups, keeping ZRAM enabled and adding an NVMe swap file is safer.

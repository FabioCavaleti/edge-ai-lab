# Commands Reference

## Networking

```bash
# SSH into Jetson via USB-C device-mode (default IP)
ssh <user>@192.168.55.1

# Show device IP addresses
hostname -I

# List available Wi-Fi networks
nmcli device wifi list

# Connect to a Wi-Fi network
nmcli device wifi connect <ssid> password <password>
```

## GitHub SSH

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Print public key to add to GitHub
cat ~/.ssh/id_ed25519.pub
```

## System info

```bash
# Jetson model, L4T version, kernel, power mode
cat /proc/device-tree/model
cat /etc/nv_tegra_release
uname -r
sudo nvpmodel -q

# Live resource usage (RAM, CPU, GPU, thermals, power)
tegrastats

# Show current default systemd boot target
systemctl get-default
```

## Memory and swap

```bash
# Show current memory and swap usage
free -h

# Show active swap devices
swapon --show

# Create and enable a swap file (change size as needed)
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Resize existing swap file
sudo swapoff /swapfile
sudo rm /swapfile
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

To make swap persistent, add to `/etc/fstab`:
```
/swapfile none swap sw,pri=10 0 0
```

## Headless mode (disable desktop GUI)

```bash
# Switch to headless mode (takes effect after reboot)
sudo systemctl set-default multi-user.target
sudo reboot

# Switch back to graphical mode
sudo systemctl set-default graphical.target
sudo reboot

# Switch to headless immediately (requires SSH already working)
sudo systemctl isolate multi-user.target

# Re-enable camera daemon if disabled after switching targets
sudo systemctl enable --now nvargus-daemon
```

## Docker

```bash
# Install Docker and NVIDIA container support
sudo apt update
sudo apt install -y nvidia-container curl jq
curl -fsSL https://get.docker.com | sh
sudo systemctl --now enable docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl daemon-reload && sudo systemctl restart docker

# Set NVIDIA runtime as Docker's default
sudo sh -c 'test -f /etc/docker/daemon.json || echo "{}" > /etc/docker/daemon.json'
sudo jq '. + {"default-runtime": "nvidia"}' /etc/docker/daemon.json | \
  sudo tee /etc/docker/daemon.json.tmp > /dev/null && \
  sudo mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
sudo systemctl daemon-reload && sudo systemctl restart docker

# Allow current user to run Docker without sudo
sudo usermod -aG docker "$USER"
newgrp docker

# Verify runtime configuration
docker info | grep -E "Runtimes|Default Runtime"

# Troubleshoot: check daemon.json for invalid keys
sudo dockerd --validate --config-file /etc/docker/daemon.json

# Troubleshoot: reset failed state after too many restarts
sudo systemctl reset-failed docker.service
sudo systemctl start docker.service
```

## Tailscale

```bash
# Authenticate and join your Tailscale network
sudo tailscale up

# Show connected devices and status
tailscale status

# Show this device's Tailscale IP
tailscale ip

# SSH into the Jetson from another machine on the tailnet
ssh <user>@<tailscale-ip>
ssh <user>@ai-lab          # if MagicDNS is enabled

# Disconnect (keeps the daemon running, just leaves the network)
sudo tailscale down

# Re-authenticate (e.g. after key expiry)
sudo tailscale up --force-reauth
```

## AI Skills (Jetson)

```bash
# Install Jetson device skills (run on the Jetson)
git clone https://github.com/NVIDIA-AI-IOT/jetson-device-skills.git
cd jetson-device-skills
bash ./install.sh

# Install BSP skills (run on the host machine)
git clone https://github.com/NVIDIA-AI-IOT/jetson-bsp-skills.git
cd jetson-bsp-skills
bash ./setup.sh --workspace <workspace_path>

# Run memory audit (before/after changes)
bash ~/.claude/skills/jetson-memory-audit/scripts/audit.sh --human > audit_before.txt

# Generate headless-mode plan
bash ~/.claude/skills/jetson-headless-mode/scripts/plan.sh --audit audit_before.txt --human > plan.json

# Apply headless-mode plan (dry-run by default, add --apply to execute)
bash ~/.claude/skills/jetson-headless-mode/scripts/apply.sh --plan plan.json
bash ~/.claude/skills/jetson-headless-mode/scripts/apply.sh --plan plan.json --apply
```

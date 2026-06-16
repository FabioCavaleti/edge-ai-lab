# Edge AI Lab — Jetson Orin Nano

This repository is a practical learning lab for Edge AI on the NVIDIA Jetson Orin Nano.

The goal is to document the process of setting up, understanding, and experimenting with a Jetson-based AI system, with focus on reproducibility, Docker-based deployment, GPU acceleration, resource constraints, and production-oriented edge AI practices.

This is not a polished framework or a finished product. It is a technical notebook built around real setup notes, experiments, troubleshooting, and explanations.

## What This Repository Covers

* Jetson Orin Nano setup notes
* NVMe installation and flashing observations
* SSH and networking setup
* GitHub SSH configuration
* Docker installation on Jetson
* NVIDIA container runtime configuration
* GPU-enabled container validation
* Resource optimization for headless usage
* Swap configuration
* Linux and system-level notes
* Edge AI deployment experiments

## Why This Exists

Running AI models on edge devices is not only about model accuracy.

A real Edge AI system also depends on:

* hardware constraints
* operating system setup
* GPU runtime configuration
* containerized deployment
* memory limitations
* inference performance
* observability
* security
* maintainability

This repository documents those practical details while I explore how to build reliable AI systems on embedded NVIDIA hardware.

## Current Notes

The first part of this repository focuses on the base Jetson setup:

```text
00-setup/
├── setup-notes.md
├── commands.md
└── troubleshooting.md
```

Topics covered:

* installing an NVMe SSD
* flashing the Jetson with NVIDIA SDK Manager
* connecting through USB-C SSH
* configuring Wi-Fi
* setting up GitHub SSH keys
* installing Docker
* configuring the NVIDIA container runtime
* setting NVIDIA as Docker’s default runtime
* disabling the desktop GUI for headless usage
* adding NVMe-backed swap

## Verification

A small setup verification script is included to check basic system information after setup:

```text
scripts/verify-setup.sh
```

It checks information such as:

* Jetson model
* Jetson Linux / L4T version
* disk layout
* memory and swap
* network information
* Docker installation
* Docker runtime configuration
* NVIDIA container runtime availability

## Notes

These notes are based on my own setup process and experiments. They are not a replacement for the official NVIDIA documentation, but they may be useful for others going through a similar path.

---

id: 36c5d653-3018-485d-8b24-b641557a5b6d

is_completed: true

version: 1

---


# Build Dev Container on Apple Silicon (M1)


- [x] Make Initialization Scripts Cross-Platform (macOS Support) <!-- id: 07d56379-fa79-479e-af6a-ae30c61025d5 -->
  - [x] Update initialize_devcontainer.sh with OS detection and mkcert logic <!-- id: ccae2e48-214e-42c2-81c0-7a985afe217c -->
  - [x] Fix stat compatibility and /etc/timezone for macOS <!-- id: 868ef8cb-5972-4d9a-94cc-02e2a7188710 -->

- [x] Fix Architecture Hardcoding in Dockerfile Tools <!-- id: ef788881-1d69-4b5c-b4d7-0462a8bcfce2 -->
  - [x] Update install_aws_cli.sh for aarch64 <!-- id: 252d09e7-b437-4a6b-8978-a9b0b90ed0a8 -->
  - [x] Update install_gh_cli.sh for arm64 <!-- id: 9fd61dca-a767-49f3-baf3-f6bb7af9619b -->

- [x] X11 and Base Image Documentation <!-- id: a2e1714d-db82-4519-95b1-e18f10811811 -->
  **X11 and Base Image Documentation for Apple Silicon (M1)**
  - **Base Image:** Use `ubuntu:22.04` (ARM64) or `mcr.microsoft.com/devcontainers/base:ubuntu` for native M1 support.
  - **X11 Forwarding:** Requires XQuartz on macOS. Ensure "Allow connections from network clients" is enabled. Pass `DISPLAY=host.docker.internal:0` in the container configuration.

- [x] Build and Test on M1 <!-- id: 43a485e2-762e-4017-8c3d-27729ed3cda6 -->
  Tested and verified dev container build successfully on Apple Silicon M1. Architecture tools resolved natively to aarch64.


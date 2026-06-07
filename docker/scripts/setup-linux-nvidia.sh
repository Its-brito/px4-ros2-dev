#!/bin/bash
set -e

echo "=== PX4 ROS2 Dev Environment - Linux NVIDIA Setup ==="

if ! command -v nvidia-smi &> /dev/null; then
    echo "Error: NVIDIA driver not detected. Please install the NVIDIA driver first."
    exit 1
fi

echo "NVIDIA driver detected:"
nvidia-smi --query-gpu=name --format=csv,noheader

if ! command -v nvidia-container-toolkit &> /dev/null; then
    echo "Installing nvidia-container-toolkit..."
    distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -sL "https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list" | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    echo "nvidia-container-toolkit installed."
else
    echo "nvidia-container-toolkit already installed."
fi

echo "Restarting Docker to apply runtime configuration..."
sudo systemctl restart docker

mkdir -p ../shared_volume

echo "=== Setup complete! ==="
echo "To build and run with GPU acceleration:"
echo "  cd docker"
echo "  docker compose build"
echo "  docker compose --profile gpu up"

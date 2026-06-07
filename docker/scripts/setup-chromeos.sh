#!/bin/bash
set -e

echo "=== PX4 ROS2 Dev Environment - Chrome OS Setup ==="

if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in for group changes to take effect."
else
    echo "Docker already installed."
fi

echo "Configuring X11 access..."
xhost +local:docker 2>/dev/null || echo "Run 'xhost +local:docker' manually if X11 forwarding fails."

mkdir -p ../shared_volume

echo "=== Setup complete! ==="
echo "To build and run:"
echo "  cd docker"
echo "  docker compose build"
echo "  docker compose up"

# PX4-ROS2-Gazebo Docker Environment

Docker setup for PX4 SITL + ROS 2 Humble + Gazebo Harmonic development on resource-constrained machines (8GB RAM).

## Prerequisites

- Docker (with `sudo` access or docker group membership)
- An X11 server (for GUI forwarding)
- At least 15GB free disk space

## Build the Docker Image

```bash
cd docker
docker compose build px4-ros2
```

The build uses `make -j2` to limit parallel compilation, preventing OOM kills on low-memory machines. The running container is also capped at 6GB via `mem_limit`.

## Run the Container

Start an interactive shell:

```bash
HOST_UID=$(id -u) HOST_GID=$(id -g) sudo -E docker compose -f docker/docker-compose.yml run --rm -it px4-ros2
```

Run in background:

```bash
sudo docker compose -f docker/docker-compose.yml up -d px4-ros2
sudo docker exec -it px4-ros2-dev bash
```

Stop the container:

```bash
sudo docker compose -f docker/docker-compose.yml down
```

### Notes

- The host `shared_volume/` directory is mounted at `/home/devuser/shared_volume` inside the container — put your code there to share with the host.
- If `/dev/dri` doesn't exist on your system (common on ARM / headless), comment out the `devices` section under `px4-ros2` in `docker-compose.yml`.
- Set `DISPLAY` if GUI forwarding is needed: `export DISPLAY=:0` on the host before running.

## Inside the Container: Setup & Launch

The `shared_volume/` directory contains two convenience scripts.

### One-time Setup

```bash
cd ~/shared_volume
./setup.sh
```

This clones and builds:
- **PX4-Autopilot** (v1.15.4, Gazebo SITL target)
- **ROS2 workspace** with `px4_msgs` and `px4_ros_com`

Safe to re-run — skips already-cloned repos.

### Launch Everything

```bash
./launch.sh
```

Opens a tmux session with three windows:

| Window | Process |
|--------|---------|
| 0 (PX4) | `make px4_sitl gz_x500` |
| 1 (Agent) | `MicroXRCEAgent udp4 -p 8888` |
| 2 (Bridge) | `ros2 launch px4_ros_com px4_ros_com_launch.py` |

**tmux cheatsheet**: `Ctrl+B` then arrow keys to switch windows, `Ctrl+B 0/1/2` to jump directly.

## Troubleshooting

### Docker build gets killed / out of memory

The `Dockerfile` already limits compilation to `-j2`. If you still see OOM kills:

```bash
# Ensure swap is enabled on the host
sudo swapon --show
# If empty, add a 4GB swap file
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```

### Permission denied on Docker socket

Run commands with `sudo` or add your user to the `docker` group:

```bash
sudo usermod -aG docker $USER
# log out and back in
```

### Gazebo GUI not showing

Ensure X11 forwarding is set up:

```bash
# On host
xhost +local:docker
export DISPLAY=:0
```

### `/dev/dri` not found

On ARM systems or systems without a GPU, comment out the `devices` section in `docker-compose.yml`:

```yaml
# devices:
#   - /dev/dri:/dev/dri
```

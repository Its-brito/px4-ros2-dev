# PX4-ROS2-Gazebo Development Environment

Docker-based development environment for PX4 SITL + ROS 2 Humble + Gazebo Harmonic on resource-constrained machines (8GB RAM).

Includes support for custom airframes such as the **Swan K-1 HWing** (VTOL quad tailsitter).

## Prerequisites

- Docker (with `sudo` access or docker group membership)
- An X11 server (for GUI forwarding)
- At least 15GB free disk space

## Quick Start

### 1. Build the Docker Image

```bash
cd docker
docker compose build px4-ros2
```

The build uses `make -j2` to limit parallel compilation, preventing OOM kills on low-memory machines. The running container is capped at 6GB via `mem_limit`.

### 2. Run the Container

```bash
HOST_UID=$(id -u) HOST_GID=$(id -g) sudo -E docker compose -f docker/docker-compose.yml run --rm -it px4-ros2
```

Run in background:

```bash
sudo docker compose -f docker/docker-compose.yml up -d px4-ros2
sudo docker exec -it px4-ros2-dev bash
```

### 3. Setup PX4 and ROS2

Inside the container, run the setup script. This clones and builds PX4-Autopilot, the ROS2 bridge, and optionally integrates custom airframe models (like Swan K1).

```bash
cd ~/shared_volume

# Default: build PX4 with x500 quadcopter
./setup.sh

# Or build with Swan K1 tailsitter
./setup.sh swan_k1_hwing
```

### 4. Launch Simulation

```bash
# Default x500 quadcopter
./launch.sh

# Swan K1 tailsitter
./launch.sh --model swan_k1_hwing

# Headless mode (no Gazebo GUI, saves memory)
./launch.sh --model swan_k1_hwing --headless
```

This opens a tmux session with three windows:

| Window | Process |
|--------|---------|
| 0 (PX4) | `make px4_sitl gz_<model>` |
| 1 (Agent) | `MicroXRCEAgent udp4 -p 8888` |
| 2 (Bridge) | `ros2 launch px4_ros_com px4_ros_com_launch.py` |

**tmux cheatsheet**: `Ctrl+B` then arrow keys to switch windows, `Ctrl+B 0/1/2` to jump directly.

## Swan K-1 HWing Model

The Swan K-1 HWing is a VTOL quad tailsitter adapted from the [ArduPilot SITL_Models](https://github.com/ArduPilot/SITL_Models) repository for use with PX4.

The conversion replaces ArduPilot's `ArduPilotPlugin` with PX4-compatible Gazebo plugins:
- `gz-sim-multicopter-motor-model-system` for 4 hover motors
- `gz-sim-lift-drag-system` for wing, winglets, and vertical stabilizer aerodynamics
- PX4-native sensors (IMU, GPS, barometer, magnetometer)

### Implementation

| Component | Location in PX4-Autopilot |
|-----------|--------------------------|
| Model SDF + meshes | `Tools/simulation/gz/models/swan_k1_hwing/` |
| Airframe config | `ROMFS/px4fmu_common/init.d-posix/airframes/22000_gz_swan_k1_hwing` |

The airframe type is `VTOL Quad Tailsitter` (`CA_AIRFRAME=4`) with 4 rotors and no control surfaces.

## Directory Structure

```
px4-ros2-dev/
├── docker/
│   ├── Dockerfile           # ROS2 Humble + Gazebo Harmonic + PX4 deps
│   ├── docker-compose.yml   # Container config with memory limits
│   ├── entrypoint.sh        # User namespace setup
│   └── .dockerignore
├── shared_volume/           # Mounted into container at /home/devuser/shared_volume
│   ├── setup.sh             # Clone & build script
│   ├── launch.sh            # tmux launch script
│   ├── PX4-Autopilot/       # PX4 firmware (built here)
│   ├── px4_ros2_ws/         # ROS2 workspace
│   └── SITL_Models/         # ArduPilot SITL models (asset source)
└── README.md
```

## Troubleshooting

### Docker build gets killed

The build already uses `-j2`. If still OOM-killed:

```bash
# Ensure swap is enabled
sudo swapon --show
# If empty, add a 4GB swap file
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```

### Gazebo GUI not showing

On systems without a GPU (no `/dev/dri`), use headless mode:

```bash
./launch.sh --headless
```

Or try software rendering:

```bash
export LIBGL_ALWAYS_SOFTWARE=1
```

### Permissions

```bash
# Add user to docker group
sudo usermod -aG docker $USER
# log out and back in

# Or use xhost for GUI
xhost +local:docker
```

### `/dev/dri` not found

On ARM systems, the `devices` section is already commented out in `docker-compose.yml`.

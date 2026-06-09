# PX4-ROS2-Gazebo Development Environment

Docker-based development environment for PX4 SITL + ROS 2 Humble + Gazebo Harmonic, designed to run on resource-constrained machines (8GB RAM).

Includes support for custom airframes such as the **Swan K-1 HWing** (VTOL quad tailsitter).

## Prerequisites

### Host Machine

- **Docker Engine** v20.10+ with `docker compose` plugin (v2)
- **X11 server** (for Gazebo GUI forwarding)
- **At least 15GB** free disk space
- **At least 8GB** RAM (6GB container limit configured)
- **sudo access** (for Docker, X11 config, optional swap setup)

### GPU Support (Optional)

| GPU Type | Requirement |
|----------|-------------|
| Intel / AMD | Kernel-mode driver (`/dev/dri`) — usually included out of the box |
| NVIDIA | Proprietary driver + `nvidia-container-toolkit` (see [setup script](docker/scripts/setup-linux-nvidia.sh)) |

## Getting Started

### 1. Clone the Repository

```bash
git clone git@github.com:Its-brito/px4-ros2-dev.git
cd px4-ros2-dev
```

### 2. Host Setup

#### Allow X11 forwarding

```bash
xhost +local:docker
```

To make this permanent, add it to your shell profile (`~/.bashrc` or `~/.zshrc`).

#### (NVIDIA only) Install nvidia-container-toolkit

Run the included setup script:

```bash
cd docker && bash scripts/setup-linux-nvidia.sh && cd ..
```

This installs `nvidia-container-toolkit`, configures the Docker runtime, and restarts Docker.

### 3. Build the Docker Image

```bash
cd docker
docker compose build px4-ros2
```

The build uses `make -j2` to limit parallel compilation, preventing OOM kills on low-memory machines. The running container is capped at 6GB via `mem_limit`.

> **Note:** The image is ~6GB. On a slow connection, this may take 30–60 minutes.

### 4. Run the Container

#### CPU / Intel / AMD GPU

```bash
HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose -f docker/docker-compose.yml run --rm -it px4-ros2
```

#### NVIDIA GPU

```bash
HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose -f docker/docker-compose.yml --profile gpu run --rm -it px4-ros2-gpu
```

#### Run in background (detached)

```bash
HOST_UID=$(id -u) HOST_GID=$(id -g) docker compose -f docker/docker-compose.yml up -d px4-ros2
docker exec -it px4-ros2-dev bash
```

### 5. Setup PX4 and ROS2 (inside the container)

Run the setup script. This clones and builds PX4-Autopilot, the ROS2 bridge, and optionally integrates custom airframe models.

```bash
cd ~/shared_volume

# Default: build PX4 with x500 quadcopter
./setup.sh

# Or build with Swan K1 tailsitter
./setup.sh swan_k1_hwing
```

### 6. Launch Simulation

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

**tmux cheatsheet:** `Ctrl+B` then arrow keys to switch windows, `Ctrl+B 0/1/2` to jump directly.

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
│   ├── Dockerfile             # ROS2 Humble + Gazebo Harmonic + PX4 deps
│   ├── docker-compose.yml     # Container config (GUI, GPU, memory limits)
│   ├── entrypoint.sh          # User namespace setup (UID/GID mapping)
│   ├── .dockerignore
│   └── scripts/
│       ├── setup-linux-nvidia.sh  # NVIDIA container toolkit installer
│       └── setup-chromeos.sh      # ChromeOS-specific setup
├── shared_volume/             # Mounted into container at ~/shared_volume
│   ├── setup.sh               # Clone & build PX4 + ROS2 workspace
│   ├── launch.sh              # tmux session launcher
│   ├── PX4-Autopilot/         # PX4 firmware (built inside container)
│   ├── px4_ros2_ws/           # ROS2 workspace (px4_msgs, px4_ros_com)
│   └── SITL_Models/           # ArduPilot SITL models (asset source)
└── README.md
```

> `shared_volume/` is gitignored — each developer populates it by running `setup.sh` inside the container.

## Troubleshooting

### Docker build gets killed

The build already uses `-j2`. If still OOM-killed:

```bash
# Ensure swap is enabled
sudo swapon --show
# If empty, add a 4GB swap file
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```

### Gazebo GUI not showing

On systems without a GPU (no `/dev/dri`), use headless mode:

```bash
./launch.sh --headless
```

Or try software rendering:

```bash
export LIBGL_ALWAYS_SOFTWARE=1
./launch.sh
```

### Permissions

```bash
# Add user to docker group (log out and back in after)
sudo usermod -aG docker $USER

# Or allow X11 forwarding for Docker containers
xhost +local:docker
```

### `/dev/dri` not found

On ARM or virtual machines without GPU passthrough, remove or comment out the `devices` section in `docker/docker-compose.yml`:

```yaml
# devices:
#   - /dev/dri:/dev/dri
```

### Portability to another Linux machine

1. Install Docker Engine + `docker compose` plugin
2. Clone this repo: `git clone git@github.com:Its-brito/px4-ros2-dev.git`
3. Run `xhost +local:docker` for GUI forwarding
4. Build the image: `docker compose build px4-ros2`
5. Run the container (see step 4 above)
6. Inside the container, run `./setup.sh` followed by `./launch.sh`

No host packages beyond Docker are required — all dependencies are inside the container.

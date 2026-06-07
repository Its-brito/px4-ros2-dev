FROM osrf/ros:humble-desktop-full

ARG DEBIAN_FRONTEND=noninteractive

# Install base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        gnupg \
        lsb-release \
        wget \
        software-properties-common \
        sudo \
        && rm -rf /var/lib/apt/lists/*

# Install gosu for clean user switching
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) gosuArch='amd64' ;; \
        arm64) gosuArch='arm64' ;; \
        *) echo >&2 "error: unsupported arch: $dpkgArch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-${gosuArch}" -o /usr/local/bin/gosu; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version

# Add OSRF repository for Gazebo Harmonic
RUN curl -sSL https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/gazebo-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gazebo-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/gazebo-stable.list

# Install Gazebo Harmonic
RUN apt-get update && apt-get install -y --no-install-recommends \
        gz-harmonic \
        && rm -rf /var/lib/apt/lists/*

# Install PX4 build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        cmake \
        build-essential \
        g++ \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        ninja-build \
        ccache \
        astyle \
        bc \
        libncurses-dev \
        libxml2-dev \
        libxml2-utils \
        xsltproc \
        protobuf-compiler \
        && rm -rf /var/lib/apt/lists/*

# Install Python packages for PX4
RUN pip3 install --no-cache-dir \
        'empy>=3.3,<4' \
        kconfiglib \
        jsonschema \
        pyros-genmsg \
        setuptools

# Install Micro XRCE-DDS Agent v2.4.3
RUN git clone --branch v2.4.3 --depth 1 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git /tmp/Micro-XRCE-DDS-Agent \
    && cd /tmp/Micro-XRCE-DDS-Agent \
    && mkdir build && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && rm -rf /tmp/Micro-XRCE-DDS-Agent

# Install ROS2 dependencies for PX4-ROS2 bridge
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-humble-ros-base \
        ros-humble-xacro \
        ros-humble-tf2-eigen \
        ros-humble-tf2-geometry-msgs \
        ros-humble-stereo-msgs \
        ros-humble-gazebo-msgs \
        ros-humble-rosidl-default-generators \
        ros-humble-rmw-fastrtps-cpp \
        ros-humble-rmw-cyclonedds-cpp \
        python3-colcon-common-extensions \
        && rm -rf /var/lib/apt/lists/*

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

#!/bin/bash
set -e

USER_ID=${HOST_UID:-1000}
GROUP_ID=${HOST_GID:-1000}

if ! getent group $GROUP_ID > /dev/null 2>&1; then
    groupadd -g $GROUP_ID devgroup
fi

if ! id -u $USER_ID > /dev/null 2>&1; then
    useradd -m -u $USER_ID -g $GROUP_ID -s /bin/bash devuser
fi

chown -R $USER_ID:$GROUP_ID /home/devuser 2>/dev/null || true

export HOME=/home/devuser

if [ "$USER_ID" = "0" ]; then
    exec "$@"
else
    exec gosu $USER_ID "$@"
fi

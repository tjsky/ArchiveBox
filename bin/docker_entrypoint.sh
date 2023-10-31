#!/bin/bash

DATA_DIR="${DATA_DIR:-/data}"
ARCHIVEBOX_USER="${ARCHIVEBOX_USER:-archivebox}"

export PUID=${PUID:-911}
export PGID=${PGID:-911}

# Set the archivebox user UID & GID
usermod -o -u "$PUID" "$ARCHIVEBOX_USER" > /dev/null 2>&1
groupmod -o -g "$PGID" "$ARCHIVEBOX_USER" > /dev/null 2>&1

export PUID="$(id -u archivebox)"
export PGID="$(id -g archivebox)"

chown $ARCHIVEBOX_USER:$ARCHIVEBOX_USER "$DATA_DIR"

# Check the permissions of the data dir (or create if it doesn't exist)
if [[ -d "$DATA_DIR/archive" ]]; then
    if touch "$DATA_DIR/archive/.permissions_test_safe_to_delete" 2>/dev/null; then
        # It's fine, we are able to write to the data directory
        rm "$DATA_DIR/archive/.permissions_test_safe_to_delete"
        # echo "[√] Permissions are correct"
    else
        echo -e "\n[X] Error: archivebox user (PUID=$PUID) is not able to write to your ./data dir." >&2
        echo -e "    Change ./data to be owned by PUID=$PUID PGID=$PGID on the host and retry:"
        echo -e "       \$ chown -R $PUID:$PGID ./data\n" >&2
        echo -e "    Configure the PUID & PGID environment variables to change the desired owner:" >&2
        echo -e "       https://docs.linuxserver.io/general/understanding-puid-and-pgid\n" >&2
        exit 1
    fi
else
    # create data directory
    mkdir -p "$DATA_DIR/logs"
fi

# force set the ownership of the data dir contents to the archivebox user and group
# this is needed because Docker Desktop often does not map user permissions from the host properly
chown $ARCHIVEBOX_USER:$ARCHIVEBOX_USER "$DATA_DIR"/*

# Drop permissions to run commands as the archivebox user
if [[ "$1" == /* || "$1" == "bash" || "$1" == "sh" || "$1" == "echo" || "$1" == "cat" || "$1" == "archivebox" ]]; then
    # handle "docker run archivebox /some/non-archivebox/command" by executing args as direct bash command
    # e.g. "docker run archivebox /venv/bin/archivebox-alt init"
    #      "docker run archivebox /bin/bash -c '...'"
    #      "docker run archivebox echo test"
    exec gosu "$ARCHIVEBOX_USER" bash -c "$*"
else
    # handle "docker run archivebox add ..." by running args as archivebox $subcommand
    # e.g. "docker run archivebox add https://example.com"
    #      "docker run archivebox manage createsupseruser"
    #      "docker run archivebox server 0.0.0.0:8000"
    exec gosu "$ARCHIVEBOX_USER" bash -c "archivebox $*"
fi

#!/bin/bash

MOUNTPOINT="/mnt/windows"
USER_HOME="/home/thadfake"

# Stop if Windows is not mounted
if ! mountpoint -q "$MOUNTPOINT"; then
    echo "ERROR: Windows partition is not mounted. Exiting."
    exit 1
fi

# Windows paths
declare -A FOLDERS=(
    ["Desktop_Windows"]="Users/meina/OneDrive/Desktop/"
    ["Documents"]="Users/meina/OneDrive/Documentos/"
    ["Downloads"]="Users/meina/Downloads/"
    ["Pictures"]="Users/meina/OneDrive/Pictures/"
    ["Music"]="Users/meina/Music/"
    ["Videos"]="Users/meina/Videos/"
)

# Create symlinks safely
for DIR in "${!FOLDERS[@]}"; do
    WIN_PATH="$MOUNTPOINT/${FOLDERS[$DIR]}"
    LINK_PATH="$USER_HOME/$DIR"

    if [ -d "$WIN_PATH" ] && [ ! -L "$LINK_PATH" ]; then
        ln -s "$WIN_PATH" "$LINK_PATH"
        echo "Symlink created: $LINK_PATH → $WIN_PATH"
    fi
done


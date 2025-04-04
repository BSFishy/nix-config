#!/usr/bin/env bash

set -e

# Default values
DISTRO="debian"
VERSION="12"

# Help message
usage() {
  echo "Usage: $0 <container-name> [distro] [version]"
  echo "  container-name: required"
  echo "  distro: default 'debian'"
  echo "  version: default '12'"
  exit 1
}

# Check arguments
if [[ -z "$1" ]]; then
  usage
fi

NAME="$1"
DISTRO="${2:-$DISTRO}"
VERSION="${3:-$VERSION}"
IMAGE="images:${DISTRO}/${VERSION}"

# Check if container exists
if incus list --format csv | cut -d',' -f1 | grep -qx "$NAME"; then
  echo "Container '$NAME' already exists."
else
  echo "Creating container '$NAME' with image '$IMAGE'..."
  incus launch "$IMAGE" "$NAME"
fi

# Check if container is running
STATUS=$(incus list "$NAME" --format csv | cut -d',' -f2)
if [[ "$STATUS" != "RUNNING" ]]; then
  echo "Starting container '$NAME'..."
  incus start "$NAME"
fi

# Connect to the container
echo "Connecting to container '$NAME'..."
incus exec "$NAME" --force-interactive -- bash

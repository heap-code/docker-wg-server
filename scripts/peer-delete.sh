#!/bin/sh

# Delete an existing peer directory and remove all associated peer configuration data.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/peer.sh"

PEER_NAME=${1:-}
if [ -z "$PEER_NAME" ]; then
	echo "Usage: $0 <peer-name>" >&2
	exit 1
fi

PEER_DIR=$(peer_dir "$PEER_NAME")
if [ -e "$PEER_DIR" ]; then
	rm -rf "$PEER_DIR"
fi

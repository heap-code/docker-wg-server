#!/bin/sh

# Show the stored configuration and state of an existing peer.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/peer.sh"

PEER_NAME=${1:-}
if [ -z "$PEER_NAME" ]; then
	echo "Usage: $0 <peer-name>" >&2
	exit 1
fi

peer_dir_require "$PEER_NAME" > /dev/null || exit 1
cat "$(peer_client_path "$PEER_NAME")"

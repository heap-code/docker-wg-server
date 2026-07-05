#!/bin/sh

# Disable an existing peer by marking its state as disabled
#	without failing if it is already disabled.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/peer.sh"

PEER_NAME=${1:-}
if [ -z "$PEER_NAME" ]; then
	echo "Usage: $0 <peer-name>" >&2
	exit 1
fi

echo '1' > "$(peer_state_disabled_path "$PEER_NAME")"

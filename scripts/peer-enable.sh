#!/bin/sh

# Re-enable an existing peer by clearing its disabled state
#	without failing if it is already enabled.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/peer.sh"

PEER_NAME=${1:-}
if [ -z "$PEER_NAME" ]; then
	echo "Usage: $0 <peer-name>" >&2
	exit 1
fi

echo '' > "$(peer_state_disabled_path "$PEER_NAME")"

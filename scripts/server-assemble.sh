#!/bin/sh

# Assemble the WireGuard server configuration by combining the server interface definition with all enabled peer configurations.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/peer.sh"

if [ ! -f "$WG_SERVER_DIR/if.conf" ]; then
	echo "Error: server interface config not found at $WG_SERVER_DIR/if.conf" >&2
	exit 1
fi

echo "Assembling wireguard server config with all available peers"
{
	cat "$WG_SERVER_DIR/if.conf"

	for peer_dir in "$WG_PEERS_DIR"/*; do
		[ -d "$peer_dir" ] || continue

		peer_name=$(basename "$peer_dir")
		disabled_file=$(peer_state_disabled_path "$peer_name")
		if [ -f "$disabled_file" ]; then
			disabled_state=$(cat "$disabled_file" 2> /dev/null)
			if [ "$disabled_state" = "1" ]; then
				continue
			fi
		fi

		peer_conf=$(peer_conf_path "$peer_name")
		if [ -f "$peer_conf" ]; then
			echo ""
			echo "# PEER $peer_name"
			cat "$peer_conf"
		fi
	done
} > "$WG_CONF"

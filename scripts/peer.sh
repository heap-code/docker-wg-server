#!/bin/sh

# Shared helper functions for peer-related scripts.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

# Get the directory of a peer
peer_dir() {
	NAME=${1:-}
	echo "$WG_PEERS_DIR/$NAME"
}

# Verify the directory of a peer and "return it"
peer_dir_require() {
	NAME=${1:-}
	DIR=$(peer_dir "$NAME")

	if [ ! -d "$DIR" ]; then
		echo "Error: peer \"$NAME\" not found" >&2
		exit 1
	fi

	echo "$DIR"
}

# Get the director of the state content of a peer
peer_state_dir() {
	NAME=${1:-}
	echo "$(peer_dir "$NAME")/state"
}
# Get the disabled state filepath of a peer
peer_state_disabled_path() {
	NAME=${1:-}
	echo "$(peer_state_dir "$NAME")/disabled"
}
# Get the peer configuration filepath of a peer
peer_conf_path() {
	NAME=${1:-}
	echo "$(peer_dir_require "$NAME")/peer.conf"
}
# Get the client configuration filepath of a peer
peer_client_path() {
	NAME=${1:-}
	echo "$(peer_dir_require "$NAME")/client.conf"
}

# Convert a IP string to an integer
ip2int() {
	ip=$1

	a=${ip%%.*}
	ip=${ip#*.}
	b=${ip%%.*}
	ip=${ip#*.}
	c=${ip%%.*}
	d=${ip#*.}

	echo $((a << 24 | b << 16 | c << 8 | d))
}

# Convert an integer to its IP representation
int2ip() {
	ip=$1
	printf '%d.%d.%d.%d\n' \
		$(((ip >> 24) & 255)) \
		$(((ip >> 16) & 255)) \
		$(((ip >> 8) & 255)) \
		$((ip & 255))
}

#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

# Fail at startup rather than when creating the first peer
peer_dns_require || exit 1
peer_endpoint_require || exit 1

case "$WG_INIT_MODE" in
	recreate)
		echo "[recreate mode] recreate the server configuration (keys, ...)"
		. "$SCRIPT_DIR/server-init.sh"

		echo "[recreate mode] create final wireguard config"
		. "$SCRIPT_DIR/server-assemble.sh"
		;;
	static)
		echo "[static] simply run the stored configuration"
		;;
	"")
		if [ ! -d "$WG_SERVER_DIR" ]; then
			echo "[normal] server uninitialized: creating server files (keys, ...)"
			. "$SCRIPT_DIR/server-init.sh"
		fi

		echo "[normal] create/refresh final wireguard config"
		. "$SCRIPT_DIR/server-assemble.sh"
		;;
	*)
		echo "Unsupported mode value: $WG_INIT_MODE" >&2
		exit 1
		;;
esac

cleanup() {
	wg-quick down "$WG_CONF" || true
	exit 0
}
trap cleanup INT TERM

# Starting wg
wg-quick up "$WG_CONF"

while true; do
	sleep 3600
done

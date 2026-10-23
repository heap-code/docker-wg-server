# shellcheck shell=sh
# shellcheck disable=SC2034 # sourced: variables are used by the other scripts

# Only use when running from outside the image (ipcalc has difference implementation depending on the OS)
# alias ipcalc="docker run --rm -t rrvzero/ipcalc ipcalc"

# Used to keep a trace of when the files have been generate
#	In case, at some time, migration or compatibility will be created
WG_VERSION="0.0.1"

# From ENV (and defaults if not set)
WG_CONFIG_DIR="${WG_CONFIG_DIR:-/etc/wireguard}"
WG_INTERFACE="${WG_INTERFACE:-wg0}"

# ENV for server configuration
WG_SERVER_PORT="${WG_SERVER_PORT:-51820}"
WG_SUBNET="${WG_SUBNET:-10.20.30.0/24}"

# Can be empty, 'static' or 'recreate' (see server-run.sh)
WG_INIT_MODE="${WG_INIT_MODE:-}"

# ENV for peer configuration (mostly when creating new configuration)
PEER_ALLOWED_IPS="${PEER_ALLOWED_IPS:-0.0.0.0/0}"
# No default: PEER_DNS and/or PEER_DNS_SELF must be set (see peer_dns_require)
PEER_DNS="${PEER_DNS:-}"
PEER_DNS_SELF="${PEER_DNS_SELF:-false}"
PEER_ENDPOINT="${PEER_ENDPOINT:-}"
PEER_ENDPOINT_PORT="${PEER_ENDPOINT_PORT:-$WG_SERVER_PORT}"
PEER_KEEP_ALIVE="${PEER_KEEP_ALIVE:-25}"

## -----------
# Computed/Deduced from given ENV
## -----------

# Configuration for the server
WG_CONF="$WG_CONFIG_DIR/$WG_INTERFACE.conf"

# Peer directory -> store private/public keys + configuration file
WG_PEERS_DIR="$WG_CONFIG_DIR/peers"

# Server directory -> store private/public keys
WG_SERVER_DIR="$WG_CONFIG_DIR/server"

WG_SERVER_KEY_PRI_PATH="$WG_SERVER_DIR/key-private"
WG_SERVER_KEY_PUB_PATH="$WG_SERVER_DIR/key-public"

# The client DNS must be chosen explicitly
peer_dns_require() {
	if [ -z "$PEER_DNS" ] && [ "$PEER_DNS_SELF" != "true" ]; then
		echo "Error: no DNS for the peers: set PEER_DNS (e.g. 1.1.1.1) and/or PEER_DNS_SELF=true" >&2
		return 1
	fi
}

# Without it, the client configs would get `Endpoint = :<port>`
peer_endpoint_require() {
	if [ -z "$PEER_ENDPOINT" ]; then
		echo "Error: no endpoint for the peers: set PEER_ENDPOINT (public hostname/IP of this server)" >&2
		return 1
	fi
}

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
PEER_DNS="${PEER_DNS:-"1.1.1.1"}"
PEER_DNS_SELF="${PEER_DNS_SELF:-false}"
PEER_ENDPOINT=$PEER_ENDPOINT
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

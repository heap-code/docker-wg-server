#!/bin/sh

# Create peers files (configuration and state)
# The allocated IP is stored to avoid to re-used for another peer

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/peer.sh"

PEER_NAME=${1:-}
if [ -z "$PEER_NAME" ]; then
	echo "Usage: $0 <peer-name>" >&2
	exit 1
fi

case "$PEER_NAME" in
	*[!A-Za-z0-9_-]*)
		echo "Error: peer name must only contain letters, numbers, '-' or '_'" >&2
		exit 1
		;;
esac

peer_dns_require || exit 1

PEER_DIR=$(peer_dir "$PEER_NAME")
if [ -e "$PEER_DIR" ]; then
	echo "Error: peer \"$PEER_NAME\" already exists" >&2
	exit 1
fi

# Create folders for the peer
PEER_DIR_KEYS_PATH="$PEER_DIR/keys"
PEER_DIR_STATE=$(peer_state_dir "$PEER_NAME")

echo "Creating peer folder"
mkdir -p "$PEER_DIR_KEYS_PATH"
mkdir -p "$PEER_DIR_STATE"

# Peer is enabled by default
echo "" > "$(peer_state_disabled_path "$PEER_NAME")"
echo "$WG_VERSION" > "$PEER_DIR_STATE/version"

# Path to keys of the peer
PEER_DIR_KEY_PRI_PATH="$PEER_DIR_KEYS_PATH/private"
PEER_DIR_KEY_PUB_PATH="$PEER_DIR_KEYS_PATH/public"
PEER_DIR_KEY_PSK_PATH="$PEER_DIR_KEYS_PATH/shared"
# Path to the configuration files of the peer
#	PEER_CLIENT_ON_FLY - the client conf could be generate on the fly
PEER_CLIENT_CONF=$(peer_client_path "$PEER_NAME")
PEER_PEER_CONF=$(peer_conf_path "$PEER_NAME")

echo "Generate peer keys"
umask 077
wg genpsk > "$PEER_DIR_KEY_PSK_PATH"
wg genkey > "$PEER_DIR_KEY_PRI_PATH"
PEER_PRIVATE_KEY=$(cat "$PEER_DIR_KEY_PRI_PATH")
echo "$PEER_PRIVATE_KEY" | wg pubkey > "$PEER_DIR_KEY_PUB_PATH"

#region get available IP

# Get the available ip range
IP_MIN=$(ipcalc --minaddr "$WG_SUBNET")
IP_MAX=$(ipcalc --maxaddr "$WG_SUBNET")

# Remove the ENV NAME of the output
IP_MIN=${IP_MIN#*=}
IP_MAX=${IP_MAX#*=}

# Get the integer value of the IP (to iteral)
IP_MIN=$(ip2int "$IP_MIN")
IP_MAX=$(ip2int "$IP_MAX")

# +1 -> first is reserved to VPN
IP_MIN=$((IP_MIN + 1))

# Get all allocated IPs (even for disabled config, in cas they are enabled again)
USED_IPS=$(cat "$WG_PEERS_DIR"/*/state/ip 2> /dev/null)

# Iterate on each ip (by integer value)
#	And verify if the IP is free
for i in $(seq "$IP_MIN" "$IP_MAX"); do
	ip=$(int2ip "$i")

	if ! printf '%s\n' "$USED_IPS" | grep -qxF "$ip"; then
		# Then save the iP
		echo "$ip" > "$PEER_DIR_STATE/ip"
		PEER_IP=$ip
		break
	fi
done

#endregion

# "Template" the peer configurations

PEER_PRESHARED_KEY=$(cat "$PEER_DIR_KEY_PSK_PATH")

DNS=
# Add the server as "first" DNS
if [ "$PEER_DNS_SELF" = "true" ]; then
	DNS=$(cat "$WG_SERVER_DIR/ip")
fi

# if any, add specified DNS
if [ -n "$PEER_DNS" ]; then
	DNS="${DNS:+"$DNS, "}$PEER_DNS"
fi

WG_SERVER_PUBLIC_KEY=$(cat "$WG_SERVER_KEY_PUB_PATH")
export \
	PEER_ALLOWED_IPS \
	PEER_DNS="${DNS:+"DNS = $DNS"}" \
	PEER_ENDPOINT \
	PEER_ENDPOINT_PORT \
	PEER_KEEP_ALIVE \
	PEER_IP \
	PEER_PRIVATE_KEY \
	PEER_PRESHARED_KEY \
	WG_SERVER_PUBLIC_KEY
envsubst < "$SCRIPT_DIR/templates/client.conf.tpl" > "$PEER_CLIENT_CONF"

PEER_PUBLIC_KEY=$(cat "$PEER_DIR_KEY_PUB_PATH")
export \
	PEER_IP \
	PEER_PRESHARED_KEY \
	PEER_PUBLIC_KEY
envsubst < "$SCRIPT_DIR/templates/peer.conf.tpl" > "$PEER_PEER_CONF"

echo "Peer created"
echo ""

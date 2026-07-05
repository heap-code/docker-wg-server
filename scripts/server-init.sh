#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

mkdir -p "$WG_SERVER_DIR"

# Generate private/public keys
umask 077
wg genkey > "$WG_SERVER_KEY_PRI_PATH"
WG_SERVER_PRIVATE_KEY=$(cat "$WG_SERVER_KEY_PRI_PATH")
echo "$WG_SERVER_PRIVATE_KEY" | wg pubkey > "$WG_SERVER_KEY_PUB_PATH"

# "Template" the wg server configuration

# Get the address of the server in the VPN
WG_SERVER_IP=$(ipcalc --minaddr "$WG_SUBNET")
WG_SERVER_IP=${WG_SERVER_IP#*=}

WG_SERVER_IP_PREFIX=$(ipcalc -p "$WG_SUBNET")
WG_SERVER_IP_PREFIX=${WG_SERVER_IP_PREFIX#*=}

echo "$WG_SERVER_IP" > "$WG_SERVER_DIR/ip"
echo "$WG_VERSION" > "$WG_SERVER_DIR/version"

WG_SERVER_INTERFACE="$WG_SERVER_DIR/if.conf"

export \
	WG_SERVER_ADDRESS=$(echo "$WG_SERVER_IP/$WG_SERVER_IP_PREFIX") \
	WG_SERVER_PORT \
	WG_SERVER_PRIVATE_KEY
envsubst < "$SCRIPT_DIR/templates/wg.conf.tpl" > "$WG_SERVER_INTERFACE"

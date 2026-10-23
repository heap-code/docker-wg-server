#!/bin/sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

# Rebuild the server WireGuard configuration from the current peer state.
. "$SCRIPT_DIR/server-assemble.sh"

echo "Reload running interface with updated configuration"
WG_CONF_STRIPPED=$(mktemp)
trap 'rm -f "$WG_CONF_STRIPPED"' EXIT

if ! { wg-quick strip "$WG_CONF" > "$WG_CONF_STRIPPED" && wg syncconf "$WG_INTERFACE" "$WG_CONF_STRIPPED"; } 2> /dev/null; then
	echo "wg syncconf failed; falling back to wg-quick reload" >&2
	wg-quick down "$WG_CONF" > /dev/null 2>&1 || true
	wg-quick up "$WG_CONF"
fi

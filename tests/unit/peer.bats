#!/usr/bin/env bats

# Peer management (runs inside the `test` image)

setup() {
	cd /
	export WG_CONFIG_DIR="$BATS_TEST_TMPDIR/wg"
	export PEER_ENDPOINT=vpn.example.com
	export PEER_DNS=1.1.1.1
	/scripts/server-init.sh
}

client_conf() {
	cat "$WG_CONFIG_DIR/peers/$1/client.conf"
}

peer_ip() {
	cat "$WG_CONFIG_DIR/peers/$1/state/ip"
}

@test "peer-create writes keys, state and both configs" {
	run /scripts/peer-create.sh alice
	[ "$status" -eq 0 ]

	dir="$WG_CONFIG_DIR/peers/alice"
	[ -s "$dir/keys/private" ]
	[ -s "$dir/keys/public" ]
	[ -s "$dir/keys/shared" ]
	[ -f "$dir/peer.conf" ]
	[ -f "$dir/client.conf" ]
	[ "$(cat "$dir/state/version")" = "0.0.1" ]
}

@test "peer-create client.conf matches the server" {
	/scripts/peer-create.sh alice
	conf=$(client_conf alice)

	[[ "$conf" == *"Address = 10.20.30.2/32"* ]]
	[[ "$conf" == *"Endpoint = vpn.example.com:51820"* ]]
	[[ "$conf" == *"PublicKey = $(cat "$WG_CONFIG_DIR/server/key-public")"* ]]
	[[ "$conf" == *"AllowedIPs = 0.0.0.0/0"* ]]
	[[ "$conf" == *"PersistentKeepalive = 25"* ]]
}

@test "peer-create peer.conf matches the client" {
	/scripts/peer-create.sh alice
	dir="$WG_CONFIG_DIR/peers/alice"

	grep -qxF "PublicKey = $(cat "$dir/keys/public")" "$dir/peer.conf"
	grep -qxF "PresharedKey = $(cat "$dir/keys/shared")" "$dir/peer.conf"
	grep -qxF "AllowedIPs = 10.20.30.2" "$dir/peer.conf"
	grep -qxF "PresharedKey = $(cat "$dir/keys/shared")" "$dir/client.conf"
}

@test "peer-create allocates the next free IP" {
	/scripts/peer-create.sh alice
	/scripts/peer-create.sh bob
	/scripts/peer-create.sh carol

	[ "$(peer_ip alice)" = "10.20.30.2" ]
	[ "$(peer_ip bob)" = "10.20.30.3" ]
	[ "$(peer_ip carol)" = "10.20.30.4" ]
}

@test "peer-create reuses the IP of a deleted peer, not of a disabled one" {
	/scripts/peer-create.sh alice
	/scripts/peer-create.sh bob
	/scripts/peer-create.sh carol
	/scripts/peer-delete.sh alice
	/scripts/peer-disable.sh bob

	/scripts/peer-create.sh dave
	/scripts/peer-create.sh erin

	[ "$(peer_ip dave)" = "10.20.30.2" ]
	[ "$(peer_ip erin)" = "10.20.30.5" ]
}

@test "peer-create rejects invalid names" {
	for name in "" "a b" "../x" "a/b" "a.b"; do
		run /scripts/peer-create.sh "$name"
		[ "$status" -eq 1 ]
	done
	[ ! -e "$WG_CONFIG_DIR/peers" ] || [ -z "$(ls -A "$WG_CONFIG_DIR/peers")" ]
}

@test "peer-create refuses an existing peer" {
	/scripts/peer-create.sh alice
	key=$(cat "$WG_CONFIG_DIR/peers/alice/keys/private")

	run /scripts/peer-create.sh alice
	[ "$status" -eq 1 ]
	[[ "$output" == *"already exists"* ]]
	[ "$(cat "$WG_CONFIG_DIR/peers/alice/keys/private")" = "$key" ]
}

@test "peer-create honors PEER_* overrides" {
	PEER_ALLOWED_IPS=10.20.30.0/24 PEER_ENDPOINT_PORT=443 PEER_KEEP_ALIVE=0 \
		/scripts/peer-create.sh alice
	conf=$(client_conf alice)

	[[ "$conf" == *"AllowedIPs = 10.20.30.0/24"* ]]
	[[ "$conf" == *"Endpoint = vpn.example.com:443"* ]]
	[[ "$conf" == *"PersistentKeepalive = 0"* ]]
}

# DNS matrix: PEER_DNS (unset / empty / value) x PEER_DNS_SELF

@test "dns: fails when PEER_DNS is unset and no self" {
	unset PEER_DNS
	run /scripts/peer-create.sh alice
	[ "$status" -eq 1 ]
	[[ "$output" == *"no DNS for the peers"* ]]
	[ ! -e "$WG_CONFIG_DIR/peers/alice" ]
}

@test "dns: fails when PEER_DNS is empty and no self" {
	run env PEER_DNS="" /scripts/peer-create.sh alice
	[ "$status" -eq 1 ]
	[ ! -e "$WG_CONFIG_DIR/peers/alice" ]
}

@test "dns: custom value" {
	PEER_DNS="9.9.9.9, 149.112.112.112" /scripts/peer-create.sh alice
	client_conf alice | grep -qxF "DNS = 9.9.9.9, 149.112.112.112"
}

@test "dns: self is prepended to PEER_DNS" {
	PEER_DNS_SELF=true /scripts/peer-create.sh alice
	client_conf alice | grep -qxF "DNS = 10.20.30.1, 1.1.1.1"
}

@test "dns: self only when PEER_DNS is unset" {
	unset PEER_DNS
	PEER_DNS_SELF=true /scripts/peer-create.sh alice
	client_conf alice | grep -qxF "DNS = 10.20.30.1"
}

@test "peer-show prints the client config" {
	/scripts/peer-create.sh alice

	run /scripts/peer-show.sh alice
	[ "$status" -eq 0 ]
	[ "$output" = "$(client_conf alice)" ]
}

@test "peer-show fails on a missing peer" {
	run /scripts/peer-show.sh nobody
	[ "$status" -ne 0 ]
	[[ "$output" == *"not found"* ]]
}

@test "peer-delete removes the peer" {
	/scripts/peer-create.sh alice
	/scripts/peer-delete.sh alice
	[ ! -e "$WG_CONFIG_DIR/peers/alice" ]
}

@test "ip2int and int2ip round-trip" {
	# $0 must point into /scripts for peer.sh to find lib.sh
	run sh -c '. /scripts/peer.sh; for ip in 0.0.0.0 10.20.30.1 192.168.1.255 255.255.255.255; do int2ip "$(ip2int "$ip")"; done' /scripts/peer.sh
	[ "$status" -eq 0 ]
	[ "$output" = "$(printf '%s\n' 0.0.0.0 10.20.30.1 192.168.1.255 255.255.255.255)" ]
}

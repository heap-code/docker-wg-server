#!/usr/bin/env bats

# Server initialization and assembly (runs inside the `test` image)

setup() {
	cd /
	export WG_CONFIG_DIR="$BATS_TEST_TMPDIR/wg"
}

@test "server-init creates keys, ip and interface config" {
	run /scripts/server-init.sh
	[ "$status" -eq 0 ]

	[ -s "$WG_CONFIG_DIR/server/key-private" ]
	[ -s "$WG_CONFIG_DIR/server/key-public" ]
	[ "$(cat "$WG_CONFIG_DIR/server/ip")" = "10.20.30.1" ]

	grep -qxF "Address = 10.20.30.1/24" "$WG_CONFIG_DIR/server/if.conf"
	grep -qxF "ListenPort = 51820" "$WG_CONFIG_DIR/server/if.conf"
}

@test "server-init keys are a valid pair and private" {
	/scripts/server-init.sh

	[ "$(wg pubkey < "$WG_CONFIG_DIR/server/key-private")" = "$(cat "$WG_CONFIG_DIR/server/key-public")" ]
	[ "$(stat -c %a "$WG_CONFIG_DIR/server/key-private")" = "600" ]
}

@test "server-init honors WG_SUBNET and WG_SERVER_PORT" {
	WG_SUBNET=10.0.0.0/16 WG_SERVER_PORT=1234 /scripts/server-init.sh

	[ "$(cat "$WG_CONFIG_DIR/server/ip")" = "10.0.0.1" ]
	grep -qxF "Address = 10.0.0.1/16" "$WG_CONFIG_DIR/server/if.conf"
	grep -qxF "ListenPort = 1234" "$WG_CONFIG_DIR/server/if.conf"
}

@test "server-assemble fails without an initialized server" {
	run /scripts/server-assemble.sh
	[ "$status" -ne 0 ]
	[[ "$output" == *"server interface config not found"* ]]
}

@test "server-assemble includes enabled peers only" {
	export PEER_ENDPOINT=vpn.example.com
	export PEER_DNS=1.1.1.1
	/scripts/server-init.sh
	/scripts/peer-create.sh alice
	/scripts/peer-create.sh bob
	/scripts/peer-disable.sh bob

	run /scripts/server-assemble.sh
	[ "$status" -eq 0 ]

	grep -qxF "# PEER alice" "$WG_CONFIG_DIR/wg0.conf"
	run grep -qxF "# PEER bob" "$WG_CONFIG_DIR/wg0.conf"
	[ "$status" -eq 1 ]

	/scripts/peer-enable.sh bob
	/scripts/server-assemble.sh
	grep -qxF "# PEER bob" "$WG_CONFIG_DIR/wg0.conf"
}

@test "server-run fails without PEER_DNS and PEER_DNS_SELF" {
	unset PEER_DNS PEER_DNS_SELF
	run /scripts/server-run.sh
	[ "$status" -eq 1 ]
	[[ "$output" == *"no DNS for the peers"* ]]
	[ ! -e "$WG_CONFIG_DIR/server" ]
}

@test "wg-server.sh rejects unknown commands" {
	run /wg-server.sh nope
	[ "$status" -eq 1 ]
	[[ "$output" == Usage:* ]]
}

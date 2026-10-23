#!/usr/bin/env bats

# Real WireGuard connection between a server and a client container (runs on the host, needs docker)
# Requires a host kernel with the WireGuard module and permission to run NET_ADMIN containers

IMAGE="${IMAGE:-wg-server:dev}"

setup_file() {
	export NAME="wg-it-$$"
	export SERVER="$NAME-server"
	export CLIENT="$NAME-client"

	docker network create "$NAME" > /dev/null

	# Split tunnel: no default route, so the client needs no src_valid_mark sysctl
	docker run -d --name "$SERVER" --network "$NAME" \
		--cap-add NET_ADMIN \
		-e PEER_ENDPOINT="$SERVER" \
		-e PEER_DNS_SELF=true \
		-e PEER_ALLOWED_IPS=10.20.30.0/24 \
		"$IMAGE" > /dev/null

	# Same image, used as a plain WireGuard client
	docker run -d --name "$CLIENT" --network "$NAME" \
		--cap-add NET_ADMIN \
		--entrypoint sleep \
		"$IMAGE" infinity > /dev/null

	if ! retry 20 docker exec "$SERVER" wg show wg0; then
		docker logs "$SERVER" >&3 2>&1
		echo "# server interface did not come up (is the WireGuard kernel module available?)" >&3
		return 1
	fi
}

teardown_file() {
	docker rm -f "$SERVER" "$CLIENT" > /dev/null 2>&1 || true
	docker network rm "$NAME" > /dev/null 2>&1 || true
}

# retry <attempts> <command...>: run the command every 0.5s until it succeeds
retry() {
	attempts=$1
	shift
	for _ in $(seq "$attempts"); do
		"$@" > /dev/null 2>&1 && return 0
		sleep 0.5
	done
	return 1
}

wg_server() {
	docker exec "$SERVER" /wg-server.sh "$@"
}

ping_server() {
	docker exec "$CLIENT" ping -c 1 -W 1 10.20.30.1
}

@test "client connects to the server" {
	wg_server peer-create alice
	wg_server sync

	# The DNS line would need resolvconf in the client: it is not what is tested here
	wg_server peer-show alice | grep -v '^DNS' |
		docker exec -i "$CLIENT" sh -c 'cat > /etc/wireguard/wg0.conf'
	docker exec "$CLIENT" wg-quick up wg0

	retry 10 ping_server

	# A handshake happened on the server side
	run docker exec "$SERVER" wg show wg0 latest-handshakes
	[ "$status" -eq 0 ]
	handshake=$(echo "$output" | awk '{ print $2 }')
	[ "$handshake" -gt 0 ]
}

@test "disabled peer is cut off after sync" {
	wg_server peer-disable alice
	wg_server sync

	run ping_server
	[ "$status" -ne 0 ]
}

@test "re-enabled peer reconnects after sync" {
	wg_server peer-enable alice
	wg_server sync

	# The server can't initiate (it doesn't know the client endpoint anymore) and the client only retries
	# its unanswered handshakes every 5s+, so reconnecting takes ~15s
	retry 40 ping_server
}

# WG Server

A lightweight [WireGuard](https://www.wireguard.com/) VPN server, packaged as a small Alpine-based Docker image with a simple CLI for managing peers (add, remove, enable/disable, show config).

The idea is similar to [wireguard-ui](https://github.com/ngoduykhanh/wireguard-ui) (server + peer lifecycle management around WireGuard), but CLI-only: no web UI, just commands run against the container.

## Features

- Runs a WireGuard interface via `wg-quick`.
- Server keys and configuration are generated automatically on first start.
- Peers are managed through simple commands, each peer gets its own keypair, pre-shared key and a free IP allocated from the configured subnet.
- Peer state (enabled/disabled, allocated IP) is persisted so peers can be toggled without losing their configuration.
- Live reload of peers into a running server (`sync`) without restarting the interface.

## Image

Published to GitHub Container Registry:

```sh
docker pull ghcr.io/heap-code/wg-server:latest
```

## Quick start

The container needs `NET_ADMIN` capability and access to `/dev/net/tun` to create the WireGuard interface, and should publish the WireGuard UDP port. Persist `/etc/wireguard` on a volume to keep server/peer keys across restarts.

```sh
docker run -d --name wg-server \
  --cap-add NET_ADMIN \
  --device /dev/net/tun \
  -p 51820:51820/udp \
  -e PEER_ENDPOINT=vpn.example.com \
  -v wg-data:/etc/wireguard \
  ghcr.io/heap-code/wg-server:latest
```

The default command is `run`, which starts the server (initializing it on first run, then bringing the interface up with `wg-quick`).

### docker-compose

```yaml
services:
  wg-server:
    image: ghcr.io/heap-code/wg-server:latest
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    ports:
      - "51820:51820/udp"
    environment:
      PEER_ENDPOINT: vpn.example.com
    volumes:
      - wg-data:/etc/wireguard

volumes:
  wg-data:
```

## Managing peers

Only `run` and `sync` touch the live WireGuard interface. All `peer-*` commands (`peer-create`, `peer-delete`, `peer-enable`, `peer-disable`, `peer-show`) only read/write files under `WG_CONFIG_DIR` (plus stateless `wg genkey`/`wg genpsk`/`wg pubkey` calls) — they don't require the server to be running. They can be run with `docker exec` on a running container, or as a one-off `docker run --rm` sharing the same volume:

```sh
docker exec wg-server /wg-server.sh peer-create alice
docker exec wg-server /wg-server.sh peer-show alice
docker exec wg-server /wg-server.sh peer-disable alice
docker exec wg-server /wg-server.sh peer-enable alice
docker exec wg-server /wg-server.sh peer-delete alice
```

```sh
# equivalent, without a running server, sharing the same volume
docker run --rm -v wg-data:/etc/wireguard ghcr.io/heap-code/wg-server:latest peer-create alice
```

`sync` does need the interface to exist/come up (it calls `wg syncconf`, falling back to `wg-quick` down/up), so it should be run against the running server container:

```sh
docker exec wg-server /wg-server.sh sync
```

| Command | Description | Needs a running server? |
| --- | --- | --- |
| `run` | Default entrypoint command. Initializes the server if needed, assembles the WireGuard config from all enabled peers, and starts the interface with `wg-quick`. | — (this *is* the server process) |
| `sync` | Reassembles the server configuration from current peer state and applies it to the running interface (`wg syncconf`, falling back to a `wg-quick` down/up) without downtime when possible. Use after adding/removing/toggling peers. | Yes |
| `peer-create <name>` | Creates a new peer: generates its keys and pre-shared key, allocates the next free IP in `WG_SUBNET`, and writes its `peer.conf` (server-side) and `client.conf` (to hand to the client). | No — file/keygen only |
| `peer-delete <name>` | Removes a peer's directory and all its stored configuration/keys. | No — file only |
| `peer-disable <name>` | Marks a peer as disabled; it is excluded from the assembled server config until re-enabled. | No — file only |
| `peer-enable <name>` | Clears the disabled state, allowing the peer back into the assembled server config. | No — file only |
| `peer-show <name>` | Prints the peer's client configuration (`client.conf`), ready to import into a WireGuard client. | No — file only |

Peer names may only contain letters, numbers, `-` and `_`.

Since the `peer-*` commands don't touch the live interface, any change made through them (create/delete/enable/disable) is only picked up by the running server after a `sync` (or a restart of `run`).

After `peer-create`, `peer-delete`, `peer-enable` or `peer-disable`, run `sync` (or restart the container) to apply the change to the running interface.

## Environment variables

### Server

| Variable | Default | Description |
| --- | --- | --- |
| `WG_CONFIG_DIR` | `/etc/wireguard` | Base directory where server/peer keys and configs are stored. Should be mounted as a volume. |
| `WG_INTERFACE` | `wg0` | Name of the WireGuard interface. |
| `WG_SERVER_PORT` | `51820` | UDP port the server listens on. |
| `WG_SUBNET` | `10.20.30.0/24` | VPN subnet. The first address is reserved for the server; peers get the next free addresses. |
| `WG_INIT_MODE` | *(empty)* | Controls server (re)initialization on `run`: empty initializes only if not already initialized; `static` never (re)initializes, just starts with the stored configuration; `recreate` always regenerates server keys/config on startup. |

### Peer defaults (used by `peer-create`)

| Variable | Default | Description |
| --- | --- | --- |
| `PEER_ALLOWED_IPS` | `0.0.0.0/0` | `AllowedIPs` written into the generated client config. |
| `PEER_DNS` | `1.1.1.1` | DNS server(s) written into the generated client config. |
| `PEER_DNS_SELF` | `false` | If `true`, prepends the VPN server's own address as a DNS entry. |
| `PEER_ENDPOINT` | *(required)* | Public hostname/IP clients use to reach this server; written into each generated client config. |
| `PEER_ENDPOINT_PORT` | `$WG_SERVER_PORT` | Port clients connect to (written into each generated client config). |
| `PEER_KEEP_ALIVE` | `25` | `PersistentKeepalive` value written into the generated client config. |

Note: peer defaults are only read at `peer-create` time and baked into that peer's `client.conf`; changing them afterwards does not affect already-created peers.

## Data layout

Everything lives under `WG_CONFIG_DIR` (default `/etc/wireguard`), which should be persisted:

```
/etc/wireguard/
├── wg0.conf                # Assembled server config (interface + all enabled peers)
├── server/
│   ├── key-private
│   ├── key-public
│   ├── ip
│   ├── version
│   └── if.conf              # Server [Interface] section
└── peers/
    └── <name>/
        ├── keys/
        │   ├── private
        │   ├── public
        │   └── shared        # pre-shared key
        ├── peer.conf          # [Peer] section added to the server config
        ├── client.conf        # Full client config for this peer
        └── state/
            ├── ip
            ├── version
            └── disabled       # present/"1" when the peer is disabled
```

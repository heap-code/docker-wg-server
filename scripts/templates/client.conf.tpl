[Interface]
PrivateKey = ${PEER_PRIVATE_KEY}

Address = ${PEER_IP}/32
${PEER_DNS}

[Peer]
Endpoint = ${PEER_ENDPOINT}:${PEER_ENDPOINT_PORT}
PublicKey = ${WG_SERVER_PUBLIC_KEY}
PresharedKey = ${PEER_PRESHARED_KEY}

AllowedIPs = ${PEER_ALLOWED_IPS}
PersistentKeepalive = ${PEER_KEEP_ALIVE}

FROM alpine:3.21 AS runtime

RUN apk add --no-cache envsubst ipcalc wireguard-tools

COPY wg-server.sh /wg-server.sh
COPY scripts/ /scripts

RUN chmod +x /wg-server.sh /scripts/*

ENTRYPOINT ["/wg-server.sh"]
CMD ["run"]

# Unit tests, run against the exact runtime image (`docker build --target test`)
FROM runtime AS test

RUN apk add --no-cache bats

COPY tests/unit /tests/unit

ENTRYPOINT []
CMD ["bats", "--print-output-on-failure", "/tests/unit"]

# Default (last) stage: the published image
FROM runtime

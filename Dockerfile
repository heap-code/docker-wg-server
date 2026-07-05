FROM alpine:3.21

RUN apk add --no-cache envsubst ipcalc wireguard-tools \
	&& rm -rf /var/cache/apk/*

COPY wg-server.sh /wg-server.sh
COPY scripts/ /scripts

RUN chmod +x /wg-server.sh /scripts/*

ENTRYPOINT ["/wg-server.sh"]
CMD ["run"]

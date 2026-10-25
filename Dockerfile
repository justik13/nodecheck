FROM alpine:3.21

LABEL maintainer="justik13"
LABEL description="NodeCheck (RU Edition) - VPN Node Quality & Censorship Auditor"

RUN apk add --no-cache \
    bash \
    curl \
    jq \
    util-linux \
    util-linux-misc \
    ca-certificates \
    bind-tools \
    coreutils \
    grep \
    sed \
    gawk \
    iperf3 \
    iputils \
    openssl

WORKDIR /app
COPY nodecheck.sh /app/nodecheck.sh
COPY vpncheck.sh /app/vpncheck.sh
COPY ipregion.sh /app/ipregion.sh
RUN chmod +x /app/nodecheck.sh /app/vpncheck.sh /app/ipregion.sh

ENTRYPOINT ["/app/nodecheck.sh"]
CMD []

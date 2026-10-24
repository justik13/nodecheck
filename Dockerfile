FROM alpine:3.20

LABEL maintainer="justik13"
LABEL description="VPNCheck (RU Edition) - VPN Node Quality & Censorship Auditor"

RUN apk add --no-cache \
    bash \
    curl \
    jq \
    util-linux \
    ca-certificates \
    bind-tools \
    coreutils \
    grep \
    sed \
    gawk

WORKDIR /app
COPY vpncheck.sh /app/vpncheck.sh
COPY ipregion.sh /app/ipregion.sh
RUN chmod +x /app/vpncheck.sh /app/ipregion.sh

ENTRYPOINT ["/app/vpncheck.sh"]
CMD []

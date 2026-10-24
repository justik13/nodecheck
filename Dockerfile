FROM alpine:3.20

LABEL maintainer="IPRegion VPN Team"
LABEL description="Multi-Source Geolocation, Streaming & VPN Node Quality Auditor"

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
COPY ipregion.sh /app/ipregion.sh
RUN chmod +x /app/ipregion.sh

ENTRYPOINT ["/app/ipregion.sh"]
CMD []

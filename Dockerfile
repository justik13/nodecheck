FROM ubuntu:24.04

LABEL maintainer="justik13"
LABEL description="NodeCheck (RU Edition) - Node Hardware, Network Quality, Geolocation & Access Auditor"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    jq \
    iputils-ping \
    ca-certificates \
    bind9-dnsutils \
    iperf3 \
    gawk \
    procps \
    coreutils \
    grep \
    sed \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --chmod=755 nodecheck.sh /app/nodecheck.sh

ENTRYPOINT ["/app/nodecheck.sh"]
CMD []

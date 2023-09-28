FROM golang:1.20.4-alpine3.16@sha256:6469405d7297f82d56195c90a3270b0806ef4bd897aa0628477d9959ab97a577 AS wireguard-go

# hadolint ignore=DL3018
RUN apk add --no-cache curl build-base

WORKDIR /app

ARG WG_GO_TAG=0.0.20210212

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN curl -fsSL https://git.zx2c4.com/wireguard-go/snapshot/wireguard-go-${WG_GO_TAG}.tar.xz | tar xJ && \
    make -C wireguard-go-${WG_GO_TAG} -j"$(nproc)" && \
    make -C wireguard-go-${WG_GO_TAG} install

FROM alpine:3.18@sha256:eece025e432126ce23f223450a0326fbebde39cdf496a85d8c016293fc851978

COPY --from=wireguard-go /usr/bin/wireguard-go /usr/bin/

# hadolint ignore=DL3018
RUN apk add --no-cache \
    bash \
    build-base \
    curl \
    libmnl-dev \
    iptables \
    flex \
    bison \
    bc \
    python3 \
    kmod \
    openresolv \
    iproute2 \
    libqrencode \
    gettext \
    ipcalc \
    openssl-dev \
    perl

WORKDIR /app

ARG WITH_WGQUICK=yes
ARG WG_TOOLS_TAG=v1.0.20210914

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN curl -fsSL https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-${WG_TOOLS_TAG}.tar.xz | tar xJ

# build and install wireguard-tools
RUN make -C wireguard-tools-${WG_TOOLS_TAG}/src -j"$(nproc)" && \
    make -C wireguard-tools-${WG_TOOLS_TAG}/src install

WORKDIR /app/templates

COPY server.conf peer.conf ./

WORKDIR /app

RUN curl -fsSL https://raw.githubusercontent.com/honzahommer/prips.sh/8bfab5e17539b37f1d21584da19e79f8751d6846/libexec/prips.sh -O && \
    chmod +x prips.sh

COPY entrypoint.sh ./

COPY show-peer /usr/bin/

RUN chmod +x entrypoint.sh /usr/bin/show-peer

CMD [ "/app/entrypoint.sh" ]

# set defaults for wireguard server
ENV SERVER_HOST "auto"
ENV SERVER_PORT "51820"
ENV CIDR "10.13.13.0/24"
ENV ALLOWEDIPS "0.0.0.0/0, ::/0"
ENV PEER_DNS "1.1.1.1"
ENV PEERS "4"

# set log level for userspace module
ENV LOG_LEVEL "verbose"

FROM golang:1.16.0-alpine3.13 as builder

RUN apk add curl build-base libmnl-dev iptables

WORKDIR /usr/src/app

ARG WG_GO_TAG=0.0.20210212
ARG WG_TOOLS_TAG=v1.0.20210315

RUN curl -L https://git.zx2c4.com/wireguard-go/snapshot/wireguard-go-${WG_GO_TAG}.tar.xz | tar xJ && \
    curl -L https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-${WG_TOOLS_TAG}.tar.xz | tar xJ

RUN make -C wireguard-go-${WG_GO_TAG} && \
    make -C wireguard-go-${WG_GO_TAG} install

ARG WITH_WGQUICK=yes

RUN make -C wireguard-tools-${WG_TOOLS_TAG}/src && \
    make -C wireguard-tools-${WG_TOOLS_TAG}/src install

FROM alpine:3.13

RUN apk add --no-cache bash libmnl iptables openresolv iproute2 inotify-tools

COPY --from=builder /usr/bin/wireguard-go /usr/bin/wg* /usr/bin/

COPY init.sh /init.sh

RUN chmod +x /init.sh

CMD [ "/init.sh" ]

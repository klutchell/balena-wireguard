#!/bin/sh

# dump module info to logs
modinfo /usr/src/app/wireguard.ko

# load required modules
modprobe udp_tunnel  
modprobe ip6_udp_tunnel

# load wireguard module and grep dmesg to logs
insmod /usr/src/app/wireguard.ko || true
dmesg | grep wireguard

trap "wg-quick down wg0" TERM INT QUIT EXIT

mkdir -p /dev/net
TUNFILE=/dev/net/tun
[ ! -c $TUNFILE ] && mknod $TUNFILE c 10 200

wg-quick up wg0

while inotifywait -e modify -e create /etc/wireguard
do
    # if PostUp or PostDown rules have not been provided use this opportunity to add iptables rules
    sed -e 's/echo WireGuard PostUp/iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE/' \
        -e 's/echo WireGuard PostDown/iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE/' \
        -i /etc/wireguard/server.json /etc/wireguard/wg0.conf
    
    wg-quick down wg0
    rm -f /var/run/wireguard/wg0.sock
    wg-quick up wg0
done

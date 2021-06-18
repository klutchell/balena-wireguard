#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# dump module info to logs
modinfo /app/wireguard-linux-compat/src/wireguard.ko || exit 1

# load required modules
modprobe udp_tunnel
modprobe ip6_udp_tunnel

# load wireguard module and grep dmesg to logs
insmod /app/wireguard-linux-compat/src/wireguard.ko || true
dmesg | grep wireguard

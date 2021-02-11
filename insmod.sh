#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# print version and exit if wireguard module is already loaded
if lsmod | grep wireguard >/dev/null 2>&1
then
	echo -n "wireguard version: "
	cat /sys/module/wireguard/version
	exit 0
fi

# modprobe dependencies
modprobe udp_tunnel
modprobe ip6_udp_tunnel

# dump module info to logs
modinfo /app/wireguard-linux-compat/src/wireguard.ko

# insert wireguard module and dump dmesg if it fails
if ! insmod /app/wireguard-linux-compat/src/wireguard.ko
then
	dmesg | grep wireguard
	sleep infinity
fi

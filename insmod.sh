#!/usr/bin/with-contenv bash
# shellcheck shell=bash

# dump module info to logs
modinfo /app/wireguard-linux-compat/src/wireguard.ko || exit 1

target_version="$(modinfo /app/wireguard-linux-compat/src/wireguard.ko | grep ^version: | awk '{print $2}')"

# print version and exit if wireguard module is already loaded
if lsmod | grep wireguard >/dev/null 2>&1
then
	current_version="$(</sys/module/wireguard/version)"
	[ "$current_version" = "$target_version" ] && exit 0
	echo "currently loaded wireguard version $current_version is out-of-date"
	rmmod -v wireguard
fi

# modprobe dependencies
modprobe udp_tunnel
modprobe ip6_udp_tunnel

# insert wireguard module and dump dmesg if it fails
if ! insmod /app/wireguard-linux-compat/src/wireguard.ko
then
	dmesg | grep wireguard
	sleep infinity
fi

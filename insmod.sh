#!/usr/bin/env bash

modpath="/app/wireguard-linux-compat/src/wireguard.ko"

if lsmod | grep wireguard >/dev/null 2>&1
then
	echo -n "wireguard version: "
	cat /sys/module/wireguard/version
else
	echo "modprobe udp_tunnel..."
	modprobe udp_tunnel

	echo "modprobe ip6_udp_tunnel..."
	modprobe ip6_udp_tunnel

	echo "modinfo wireguard..."
	modinfo "${modpath}"
	
	echo "insmod wireguard..."
	if ! insmod "${modpath}"
	then
	 	dmesg | grep wireguard
	fi
fi

# sleep infinity
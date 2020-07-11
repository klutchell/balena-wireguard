#!/usr/bin/env bash

# adapted from
# https://github.com/jaredallard-home/wireguard-balena-rpi/blob/9cfa2708c178cedeff5358f6887ce00a85091f28/run.sh

OS_VARIANT="${BALENA_HOST_OS_VARIANT:-prod}"
OS_VERSION=$(awk '{ print $2 }' <<< "${BALENA_HOST_OS_VERSION}")
modPath="/usr/src/app/output/wireguard-linux-compat/src_${BALENA_DEVICE_TYPE}_${OS_VERSION}.${OS_VARIANT}_from_src/wireguard.ko"
echo "OS Version is ${OS_VERSION}"

if lsmod | grep wireguard >/dev/null 2>&1
then
	cat /sys/module/wireguard/version
else
	echo "loading udp_tunnel..."
	modprobe udp_tunnel

	echo "loading ip6_udp_tunnel..."
	modprobe ip6_udp_tunnel

	echo "loading wireguard..."
	modinfo "${modPath}"
	
	if ! insmod "${modPath}"
	then
	 	dmesg | grep wireguard
	fi
fi

# sleep indefinitely for debugging
# tail -f /dev/null
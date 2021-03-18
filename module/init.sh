#!/bin/sh

modprobe udp_tunnel  
modprobe ip6_udp_tunnel  
insmod /usr/src/app/wireguard.ko || true

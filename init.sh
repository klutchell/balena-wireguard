#!/bin/bash

set -euo pipefail

# set a hostname for mDNS (default to wireguard.local)
if [ -n "${DEVICE_HOSTNAME}" ]
then
    curl -X PATCH --header "Content-Type:application/json" \
        --data "{\"network\": {\"hostname\": \"${DEVICE_HOSTNAME}\"}}" \
        "${BALENA_SUPERVISOR_ADDRESS}/v1/device/host-config?apikey=${BALENA_SUPERVISOR_API_KEY}" || true
fi

config_root=/etc/wireguard
module_path=/usr/src/app/wireguard.ko
server_template=/usr/src/app/server.conf
peer_template=/usr/src/app/peer.conf

server_conf_path="${config_root}"/wg0.conf
server_key_path="${config_root}"/wg0.key
server_pub_path="${config_root}"/wg0.pub

# dump module info to logs
modinfo "${module_path}"

# load required modules
modprobe udp_tunnel  
modprobe ip6_udp_tunnel

# load wireguard module and grep dmesg to logs
insmod "${module_path}" || true
dmesg | grep wireguard

mkdir -p "${config_root}"

ipcalc_network() {
    ipcalc -n -b "$@" | grep Network: | awk '{print $2}'
}

ipcalc_hostmin() {
    ipcalc -n -b "$@" | grep HostMin: | awk '{print $2}'
}

ipcalc_hostmax() {
    ipcalc -n -b "$@" | grep HostMax: | awk '{print $2}'
}

prips() {
    IFS=. read -r a b c d <<< "$(ipcalc_hostmin "$@")"
    IFS=. read -r e f g h <<< "$(ipcalc_hostmax "$@")"
    eval "echo {$a..$e}.{$b..$f}.{$c..$g}.{$d..$h}"
}

# lookup public ip if server host is not provided
if [ -z "${SERVER_HOST}" ] || [ "${SERVER_HOST}" = "auto" ]
then
    SERVER_HOST="$(curl -s icanhazip.com)"
fi

# generate server keys if required
if [ ! -f "${server_key_path}" ]
then
    umask 077
    wg genkey | tee "${server_key_path}" | wg pubkey > "${server_pub_path}"
fi

NETWORK="$(ipcalc_network "${NETWORK}")"
SERVER_ADDRESS="$(ipcalc_hostmin "${NETWORK}")"
SERVER_PRIVKEY="$(cat "${server_key_path}")"
SERVER_PUBKEY="$(cat "${server_pub_path}")"

# substitute env vars in server template conf
export SERVER_ADDRESS SERVER_PRIVKEY
envsubst < "${server_template}" > "${server_conf_path}"

# determine if peers is a number or a list of names
case "${PEERS}" in
   (*[!0-9]*|'') PEERS=$(echo "${PEERS}" | tr ',' ' ') ;;
   (*)           PEERS=$(seq 1 "${PEERS}") ;;
esac

for peer in ${PEERS}
do
    # peer_id is used for filenames so remove special characters
    peer_id="peer_${peer//[^[:alnum:]_-]/}"
    peer_key_path="${config_root}"/"${peer_id}".key
    peer_pub_path="${config_root}"/"${peer_id}".pub
    peer_conf_path="${config_root}"/"${peer_id}".conf

    # genrate peer keys if required
    if [ ! -f "${peer_key_path}" ]
    then
        umask 077
        wg genkey | tee "${peer_key_path}" | wg pubkey > "${peer_pub_path}"
    fi

    PEER_PRIVKEY="$(cat "${peer_key_path}")"
    PEER_PUBKEY="$(cat "${peer_pub_path}")"
    PEER_ADDRESS=

    if [ -f "${peer_conf_path}" ]
    then
        # reuse the IP address is config already exists for this peer
        PEER_ADDRESS=$(grep "Address" "${peer_conf_path}" | awk '{print $NF}')
    fi

    # assign a new IP if peer address does not match the internal subnet
    if [ "$(ipcalc_network "${PEER_ADDRESS}")" != "${NETWORK}" ]
    then
        for addr in $(prips "${NETWORK}")
        do
            # determine the first unused IP address
            PEER_ADDRESS="${addr}"
            grep -q -R "${PEER_ADDRESS}" "${config_root}"/*.conf || break
        done
    fi

    # substitute env vars in peer template conf
    export PEER_ADDRESS PEER_PRIVKEY PEER_DNS SERVER_PUBKEY SERVER_HOST SERVER_PORT ALLOWEDIPS
    envsubst < "${peer_template}" > "${peer_conf_path}"

    # add peer to server conf
    cat >> "${server_conf_path}" << EOF

[Peer]
# ${peer}
PublicKey = ${PEER_PUBKEY}
AllowedIPs = ${PEER_ADDRESS}/32
EOF

    # show-peer "${peer}"
done

trap "wg-quick down wg0" TERM INT QUIT EXIT

mkdir -p /dev/net
TUNFILE=/dev/net/tun

[ ! -c ${TUNFILE} ] && mknod ${TUNFILE} c 10 200

wg-quick up wg0

sleep infinity

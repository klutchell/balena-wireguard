#!/usr/bin/env bash

set -euo pipefail

cleanup() {
    wg-quick down wg0 || true
}

trap "cleanup" TERM INT QUIT EXIT

load_kernel_module() {
    modprobe wireguard
    dmesg | grep wireguard
}

config_root=/etc/wireguard
server_template=/app/templates/server.conf
peer_template=/app/templates/peer.conf

server_conf_path="${config_root}"/wg0.conf
server_key_path="${config_root}"/wg0.key
server_pub_path="${config_root}"/wg0.pub

load_kernel_module || true

mkdir -p "${config_root}"

# lookup public ip if server host is not provided
if [ -z "${SERVER_HOST}" ] || [ "${SERVER_HOST}" = "auto" ]
then
    SERVER_HOST="$(curl -s icanhazip.com)"
fi

echo "Assigning '${SERVER_HOST}' as host address..."

# restrict default file creation permissions
umask 077

# generate server keys if required
if [ ! -f "${server_key_path}" ]
then
    echo "Generating new keys for server..."
    wg genkey | tee "${server_key_path}" | wg pubkey > "${server_pub_path}"
fi

eval "$(ipcalc --silent --network "${CIDR}")" # NETWORK
eval "$(ipcalc --silent --minaddr "${CIDR}")" # MINADDR
eval "$(ipcalc --silent --maxaddr "${CIDR}")" # MAXADDR
eval "$(ipcalc --silent --broadcast "${CIDR}")" # BROADCAST

SERVER_ADDRESS="${MINADDR}"
SERVER_PRIVKEY="$(cat "${server_key_path}")"
SERVER_PUBKEY="$(cat "${server_pub_path}")"

echo "Assigning '${SERVER_ADDRESS}' as server address..."

AVAILABLE_IPS="$(./prips.sh "${MINADDR}" "${MAXADDR}")"

# remove server address from available addresses
# shellcheck disable=SC2001
AVAILABLE_IPS="$(sed "s/\b${SERVER_ADDRESS}\b//g" <<< "${AVAILABLE_IPS}")"

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
        echo "Generating new keys for ${peer_id}..."
        wg genkey | tee "${peer_key_path}" | wg pubkey > "${peer_pub_path}"
    fi

    PEER_PRIVKEY="$(cat "${peer_key_path}")"
    PEER_PUBKEY="$(cat "${peer_pub_path}")"
    PEER_ADDRESS="$(grep "Address" "${peer_conf_path}" 2>/dev/null | awk '{print $NF}')" || true

    # assign a new IP
    if [ -z "${PEER_ADDRESS}" ] || ! grep -wq "${PEER_ADDRESS}" <<< "${AVAILABLE_IPS}"
    then
        for addr in ${AVAILABLE_IPS}
        do
            # determine the first unused IP address
            PEER_ADDRESS="${addr}"
            grep -q "${PEER_ADDRESS}" "${config_root}"/*.conf || break
        done
    fi

    if [ -z "${PEER_ADDRESS}" ]
    then
        echo "Failed to find unused IP address for ${peer_id}!"
        tail -f /dev/null
    else
        echo "Assigning '${PEER_ADDRESS}' as ${peer_id} address..."
    fi

    # remove peer address from available addresses
    # shellcheck disable=SC2001
    AVAILABLE_IPS="$(sed "s/\b${PEER_ADDRESS}\b//g" <<< "${AVAILABLE_IPS}")"

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

done

mkdir -p /dev/net
TUNFILE=/dev/net/tun
[ ! -c ${TUNFILE} ] && mknod ${TUNFILE} c 10 200

# set file permissions
chmod 600 "${config_root}"/*

echo "Bringing interface wg0 up..."
wg-quick up wg0

tail -f /dev/null

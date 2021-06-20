#!/bin/sh

# set a hostname for mDNS (default to nextcloud.local)
if [ -n "${BALENA_HOSTNAME}" ]
then
    curl -X PATCH --header "Content-Type:application/json" \
        --data "{\"network\": {\"hostname\": \"${BALENA_HOSTNAME}\"}}" \
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

SERVER_PORT=${SERVER_PORT:-51820}
INTERNAL_SUBNET=${INTERNAL_SUBNET:-10.13.13.0}
INTERFACE=$(echo "${INTERNAL_SUBNET}" | awk 'BEGIN{FS=OFS="."} NF--')
ALLOWEDIPS=${ALLOWEDIPS:-0.0.0.0/0, ::/0}
PEER_DNS=${PEER_DNS:-1.1.1.1}

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

SERVER_PRIVKEY="$(cat "${server_key_path}")"
SERVER_PUBKEY="$(cat "${server_pub_path}")"

# substitute env vars in server template conf
export INTERFACE SERVER_PRIVKEY
envsubst < "${server_template}" > "${server_conf_path}"

# determine if peers is a number or a list of names
case "${PEERS}" in
   (*[!0-9]*|'') PEERS=$(echo "${PEERS}" | tr ',' ' ') ;;
   (*)           PEERS=$(seq 1 "${PEERS}") ;;
esac

for peer in ${PEERS}
do
    # peer_id is used for filenames so remove special characters
    peer_id="peer_$(echo "${peer}" | sed 's/[^[:alnum:]_-]//g')"
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

    if [ -f "${peer_conf_path}" ]
    then
        # reuse the IP address is config already exists for this peer
        PEER_ADDRESS=$(grep "Address" "${peer_conf_path}" | awk '{print $NF}')
    else
        for i in $(seq 2 254)
        do
            # determine the first unused IP address
            PEER_ADDRESS="${INTERFACE}.${i}"
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

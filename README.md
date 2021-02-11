# balena-wireguard

[wireguard](https://www.wireguard.com/) stack for balenaCloud

## Hardware required

- Raspberry Pi 3/3b/3b+ (note that 64-bit OS is not supported yet)

Note that this image has a hardcoded balenaOS version in the Dockerfile(s).
If your device is not running this version the wireguard module may fail to load.
If this is the case you can try to change the version to match your device
by removing the `v` prefix and replacing `+` is with `%2B`.

eg. `v2.67.3+rev4.prod` --> `2.67.3%2Brev4.prod`

## Getting Started

You can one-click-deploy this project to balena using the button below:

[![deploy with balena](https://balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/klutchell/balena-wireguard&defaultDeviceType=raspberrypi3)

## Manual Deployment

Alternatively, deployment can be carried out by manually creating a [balenaCloud account](https://dashboard.balena-cloud.com) and application,
flashing a device, downloading the project and pushing it via either Git or the [balena CLI](https://github.com/balena-io/balena-cli).

### Application Environment Variables

Application envionment variables apply to all services within the application, and can be applied fleet-wide to apply to multiple devices.

| Name              | Example                | Purpose                                                                                                                                                                    |
| ----------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SERVERURL`       | `wireguard.domain.com` | External IP or domain name for docker host. Used in server mode. If set to auto, the container will try to determine and set the external IP automatically.                |
| `SERVERPORT`      | `51820`                | External port for docker host. Used in server mode.                                                                                                                        |
| `PEERS`           | `4`                    | Number of peers to create confs for. Required for server mode.                                                                                                             |
| `PEERDNS`         | `auto`                 | DNS server set in peer/client configs (can be set as 8.8.8.8). Used in server mode. Defaults to auto, which uses wireguard docker host's DNS via included CoreDNS forward. |
| `INTERNAL_SUBNET` | `10.13.13.0`           | Internal subnet for the wireguard and server and peers (only change if it clashes). Used in server mode.                                                                   |

## Usage

If the environment variable `PEERS` is set to a number or a list of strings separated by comma,
the container will run in server mode and the necessary server and peer/client confs will be generated.
The peer/client config qr codes will be output in the docker log. They will also be saved in text and
png format under `/config/peerX` in case `PEERS` is a variable and an integer or `/config/peer_X` in case a
list of names was provided instead of an integer.

Further wireguard usage instructions for this image can be found here:

<https://docs.linuxserver.io/images/docker-wireguard>

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## References

- <https://www.balena.io/blog/how-to-run-wireguard-vpn-in-balenaos/>
- <https://www.wireguard.com/compilation/>
- <https://github.com/linuxserver/docker-wireguard>
- <https://github.com/balena-os/kernel-module-build>
- <https://github.com/jaredallard-home/wireguard-balena-rpi>

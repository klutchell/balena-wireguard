# balena-wireguard

[wireguard](https://www.wireguard.com/) stack for balenaCloud

## Requirements

- Raspberry Pi 3/4 or similar device supported by BalenaCloud

## Getting Started

To get started you'll first need to sign up for a free balenaCloud account and flash your device.

<https://www.balena.io/docs/learn/getting-started>

## Deployment

Deployment is carried out by downloading the project and pushing it to your device either via Git or the balena CLI.

<https://www.balena.io/docs/reference/balena-cli/>

### Application Environment Variables

Application envionment variables apply to all services within the application, and can be applied fleet-wide to apply to multiple devices.

| Name              | Example                | Purpose                                                                                                                                                                    |
| ----------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `TZ`              | `America/Toronto`      | Specify a timezone to use.                                                                                                                                                 |
| `SERVERURL`       | `wireguard.domain.com` | External IP or domain name for docker host. Used in server mode. If set to auto, the container will try to determine and set the external IP automatically.                |
| `SERVERPORT`      | `51820`                | External port for docker host. Used in server mode.                                                                                                                        |
| `PEERS`           | `4`                    | Number of peers to create confs for. Required for server mode.                                                                                                             |
| `PEERDNS`         | `auto`                 | DNS server set in peer/client configs (can be set as 8.8.8.8). Used in server mode. Defaults to auto, which uses wireguard docker host's DNS via included CoreDNS forward. |
| `INTERNAL_SUBNET` | `10.13.13.0`           | Internal subnet for the wireguard and server and peers (only change if it clashes). Used in server mode.                                                                   |

## Usage

<https://docs.linuxserver.io/images/docker-wireguard>

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Author

Kyle Harding <https://klutchell.dev>

[Buy me a beer](https://kyles-tip-jar.myshopify.com/cart/31356319498262:1?channel=buy_button)

[Buy me a craft beer](https://kyles-tip-jar.myshopify.com/cart/31356317859862:1?channel=buy_button)

## Acknowledgments

- <https://github.com/linuxserver/docker-wireguard>
- <https://github.com/balena-os/kernel-module-build>
- <https://github.com/jaredallard-home/wireguard-balena-rpi>

## References

- <https://www.wireguard.com/compilation/>

## License

[MIT License](./LICENSE)

# balena-wireguard

[WireGuard®](https://www.wireguard.com/) is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography.

## Hardware Required

- Raspberry Pi 3/3b/3b+
- balenaOS v2.80.3+rev1 (note that 64-bit OS is not supported)

## Getting Started

You can one-click-deploy this project to balena using the button below:

[![Deploy with balena](https://balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/klutchell/balena-wireguard&defaultDeviceType=raspberrypi3)

## Manual Deployment

Alternatively, deployment can be carried out by manually creating a [balenaCloud account](https://dashboard.balena-cloud.com) and application,
flashing a device, downloading the project and pushing it via the [balena CLI](https://github.com/balena-io/balena-cli).

### Environment Variables

A list of supported environment variables can be found here: <https://docs.linuxserver.io/images/docker-wireguard#environment-variables-e>

## Usage/Examples

Once your device joins the fleet you'll need to allow some time for it to download the application and start the services.

When it's done you should see QR codes for each peer in the application logs.

Additional usage instructions for this image can be found here: <https://docs.linuxserver.io/images/docker-wireguard#server-mode>

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Acknowledgements

- <https://www.balena.io/blog/how-to-run-wireguard-vpn-in-balenaos/>
- <https://www.wireguard.com/compilation/>
- <https://github.com/linuxserver/docker-wireguard>
- <https://github.com/balena-os/kernel-module-build>
- <https://github.com/jaredallard-home/wireguard-balena-rpi>

# balena-wireguard

[WireGuard®](https://www.wireguard.com/) is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography.

## Supported Devices

The following device and OS combinations have been somewhat tested.
Please consider updating this table and `balena.yml` if you have tried a new combination.

| Device Type                     | OS Version   |
| ------------------------------- | ------------ |
| Raspberry Pi 3                  | 2.80.3+rev1  |
| Raspberry Pi 4 (using 64bit OS) | 2.83.10+rev1 |

Note that the Fleet Architecture must match the [Device Architecture](https://www.balena.io/docs/reference/base-images/devicetypes/) for kernel module support!
For example, `armv7hf` images normally work on `aarch64` fleets but the kernel module will
be compiled for the wrong platform so only the userspace module will be available.

## Getting Started

You can one-click-deploy this project to balena using the button below:

[![Deploy with balena](https://balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/klutchell/balena-wireguard)

## Manual Deployment

Alternatively, deployment can be carried out by manually creating a [balenaCloud account](https://dashboard.balena-cloud.com) and application,
flashing a device, downloading the project and pushing it via the [balena CLI](https://github.com/balena-io/balena-cli).

### Environment Variables

| Name                | Description                                                                                                                                                                                                                                                                                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `SERVER_HOST`       | External IP or domain name for docker host. Used in server mode. If set to `auto` the container will try to determine and set the external IP automatically.                                                                                                                                                                               |
| `SERVER_PORT`       | External port for docker host. Defaults to `51820`.                                                                                                                                                                                                                                                                                        |
| `PEERS`             | Number of peers to create confs for. Can be a number like `4` or a list of names such as `myPC,myPhone,myTablet`.                                                                                                                                                                                                                          |
| `PEER_DNS`          | DNS server set in peer/client configs. Defaults to `1.1.1.1`.                                                                                                                                                                                                                                                                              |
| `CIDR`              | Internal network CIDR for the wireguard and server and peers. Defaults to `10.13.13.0/24`.                                                                                                                                                                                                                                                 |
| `ALLOWEDIPS`        | The IPs/Ranges that the peers will be able to reach using the VPN connection. If not specified the default value is `0.0.0.0/0, ::0/0`. This will cause ALL traffic to route through the VPN, if you want split tunneling, set this to only the IPs you would like to use the tunnel AND the ip of the server's WG ip, such as 10.13.13.1. |
| `DISABLE_USERSPACE` | Optionally disable the fallback [wireguard-go](https://git.zx2c4.com/wireguard-go/about/) userspace module.                                                                                                                                                                                                                                |
| `SET_HOSTNAME`      | Set a custom hostname on application start. Defaults to `wireguard`.                                                                                                                                                                                                                                                                       |

## Usage/Examples

Once your device joins the fleet you'll need to allow some time for it to download the application and start the services.

When it's done you can display QR codes for each peer by running `show-peer <peer>` in the container shell.

Additional usage instructions for wireguard can be found here: <https://www.wireguard.com/>

### Kernel Module

The default behaviour for maximum device compatibility is to compile the Wireguard kernel module on first app start.
This allows checking the version of the running Host OS before downloading kernel sources.

You can optionally build the kernel module ahead of time, during the application build stage, by setting the following
ARGS in `Dockerfile.template`.

```dockerfile
ARG BALENA_DEVICE_TYPE=%%BALENA_MACHINE_NAME%%
ARG BALENA_HOST_OS_VERSION=2.80.3+rev1
```

This makes for much faster app startup but must match the environment
of the target device.

Deploying a release with a pre-built module to an incompatible device type or version
may fail to load and instead fallback to the [wireguard-go](https://git.zx2c4.com/wireguard-go/about/) userspace module.

If either of those ARGS are not set, the module build will be postponed
until runtime when the device type and Host OS version can be checked by the script.

### Userspace Module

If the kernel module fails to build, or load, for any reason including those mentioned
above, the application will automatically use the [wireguard-go](https://git.zx2c4.com/wireguard-go/about/) userspace module
instead. This operates the same and should work on all platforms but will incur some
performance penalties.

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Versioning

Note that the current CI workflow will bump the version in
the main branch _after_ the merged balenaCloud release has
been deployed as final.

As such, breaking changes may be introduced in `x.y.z-rev`
releases in the balenaCloud dashboard with no indication
that the major version was bumped as part of the same merge.

However each balenaCloud release version (draft or final)
will be tagged on the associated git commit so that should
be used as the source of truth.

## Acknowledgements

- <https://www.balena.io/blog/how-to-run-wireguard-vpn-in-balenaos/>
- <https://www.wireguard.com/compilation/>
- <https://github.com/linuxserver/docker-wireguard>
- <https://github.com/balena-os/kernel-module-build>
- <https://github.com/jaredallard-home/wireguard-balena-rpi>

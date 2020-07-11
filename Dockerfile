
FROM balenalib/raspberrypi3-64-debian:build as build
# FROM balenalib/%%BALENA_MACHINE_NAME%%-debian:build as build

WORKDIR /usr/src/app

RUN install_packages curl wget build-essential \
    libelf-dev awscli bc flex libssl-dev python bison git pkg-config

# https://www.wireguard.com/compilation/
RUN git clone https://git.zx2c4.com/wireguard-linux-compat

# https://github.com/balena-os/kernel-module-build
ADD https://raw.githubusercontent.com/balena-os/kernel-module-build/master/build.sh .
ADD https://raw.githubusercontent.com/balena-os/kernel-module-build/master/workarounds.sh .

RUN chmod +x build.sh workarounds.sh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV BALENA_MACHINE_NAME "raspberrypi3-64"
# ENV BALENA_MACHINE_NAME "%%BALENA_MACHINE_NAME%%"
ENV VERSIONS "2.47.0+rev1.prod"

# print available versions and exit
# RUN ./build.sh list | awk '$1 == "${BALENA_MACHINE_NAME}" {print $2}' ; exit 0

RUN ./build.sh build \
    --device "${BALENA_MACHINE_NAME}" \
    --os-version "${VERSIONS}" \
    --src wireguard-linux-compat/src

FROM linuxserver/wireguard:arm64v8-latest

COPY --from=build /usr/src/app/output/ /usr/src/app/output/

COPY insmod.sh /

RUN chmod +x /insmod.sh

ENTRYPOINT [ "/bin/bash", "-c", "/insmod.sh && /init" ]

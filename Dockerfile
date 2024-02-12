FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base as build
COPY install_feeder.sh /
RUN /install_feeder.sh

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:qemu

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEASTHOST=readsb \
    BEASTPORT=30005 \
    MLAT=no \
    VERBOSE_LOGGING=false

ARG TARGETPLATFORM

COPY --from=build /usr/bin/fr24feed /usr/bin/fr24feed
COPY --from=build /usr/bin/fr24feed-status /usr/bin/fr24feed-status

# NEW STUFF BELOW
# hadolint ignore=DL3008,SC2086,SC2039,SC2068
RUN set -x && \
    # define packages to install
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # 'expect' required for signup
    #KEPT_PACKAGES+=(expect) && \
    # required monitor incoming traffic from beasthost
    KEPT_PACKAGES+=(tcpdump) && \
    # required for adding fr24 repo
    #KEPT_PACKAGES+=(gnupg) && \
    # required to extract .deb file
    #KEPT_PACKAGES+=(binutils) && \
    # required to figure out fr24feed for amd64
    KEPT_PACKAGES+=(jq) && \
    # install packages
    #KEPT_PACKAGES+=(dirmngr) && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" && \
    #
    ln -s /usr/bin/fr24feed /usr/local/bin/fr24feed && \
    ln -s /usr/bin/fr24feed-status /usr/local/bin/fr24feed-status && \
    sed -i 's|systemctl status fr24feed|grep -q /bin/fr24feed <<< $(ps -ef)|g' /usr/bin/fr24feed-status && \
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    # Document version
    if /usr/local/bin/fr24feed --version > /dev/null 2>&1; \
    then /usr/local/bin/fr24feed --version > /CONTAINER_VERSION; \
    else qemu-arm-static /usr/local/bin/fr24feed --version > /CONTAINER_VERSION; \
    fi \
    && \
    cat /CONTAINER_VERSION

COPY rootfs/ /

EXPOSE 30334/tcp 8754/tcp 30003/tcp

# Add healthcheck
HEALTHCHECK --start-period=600s --interval=600s CMD /scripts/healthcheck.sh

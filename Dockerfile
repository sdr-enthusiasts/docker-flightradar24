FROM ghcr.io/sdr-enthusiasts/docker-baseimage:qemu

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEASTHOST=readsb \
    BEASTPORT=30005 \
    MLAT=no \
    VERBOSE_LOGGING=false

COPY rootfs/ /

# NEW STUFF BELOW
RUN set -x && \
    # add armhf architecture
    dpkg --add-architecture armhf && \
    # define packages to install
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # 'expect' required for signup
    KEPT_PACKAGES+=(expect) && \
    # required for adding fr24 repo
    TEMP_PACKAGES+=(gnupg) && \
    # required to extract .deb file
    TEMP_PACKAGES+=(binutils) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # import flightradar24 gpg key
    gpg --list-keys && \
    gpg \
        --no-default-keyring \
        --keyring /usr/share/keyrings/flightradar24.gpg \
        --keyserver hkp://keyserver.ubuntu.com:80 \
        --recv-keys C969F07840C430F5 \
        && \
    gpg --list-keys && \
    # add flightradar24 repo
    echo 'deb [arch=armhf signed-by=/usr/share/keyrings/flightradar24.gpg] http://repo.feed.flightradar24.com flightradar24 raspberrypi-stable' > /etc/apt/sources.list.d/flightradar24.list && \
    apt-get update && \
    # get fr24feed:
    # instead of apt-get install, we use apt-get download.
    # this is done because the package has dependencies,
    # which we don't want in a container.
    # also, there are pre/post install tasks that won't work cross platform.
    # instead, we download, extract and manually install rbfeeder,
    # and install the dependencies manually.
    mkdir -p /tmp/fr24feed && \
    pushd /tmp/fr24feed && \
    apt-get download fr24feed:armhf && \
    popd && \
    # extract .deb file
    ar x --output=/tmp/fr24feed -- /tmp/fr24feed/*.deb && \
    # extract data.tar.gz file
    mkdir -p /tmp/fr24feed/extracted && \
    tar xvf /tmp/fr24feed/data.tar.gz -C /tmp/fr24feed/extracted && \
    # copy required files
    cp -v /tmp/fr24feed/extracted/usr/bin/fr24feed /usr/local/bin/fr24feed && \
    cp -v /tmp/fr24feed/extracted/usr/bin/fr24feed-status /usr/local/bin/fr24feed-status && \
    chmod -v a+x /usr/local/bin/fr24feed /usr/local/bin/fr24feed-status && \
    # Clean up
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

EXPOSE 30334/tcp 8754/tcp 30003/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh

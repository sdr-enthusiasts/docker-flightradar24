FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base AS build
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
COPY install_feeder.sh /

RUN \
    /install_feeder.sh && \
    sed -i "s|systemctl status fr24feed|grep -q /bin/fr24feed <<< \$(ps -ef)|g" /usr/bin/fr24feed-status

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEASTHOST=readsb \
    BEASTPORT=30005 \
    MLAT=no \
    VERBOSE_LOGGING=false

ARG VERSION_REPO="sdr-enthusiasts/docker-flightradar24" \
    VERSION_BRANCH="##BRANCH##"

RUN --mount=type=bind,from=build,source=/,target=/build/ \
    cp -f /build/usr/bin/fr24feed /usr/bin/fr24feed && \
    cp -f /build/usr/bin/fr24feed-status /usr/bin/fr24feed-status && \
    ln -s /usr/bin/fr24feed /usr/local/bin/fr24feed && \
    ln -s /usr/bin/fr24feed-status /usr/local/bin/fr24feed-status && \
    # Document version
    if [[ "${VERSION_BRANCH:0:1}" == "#" ]]; then VERSION_BRANCH="main"; fi && \
    echo "$(TZ=UTC date +%Y%m%d-%H%M%S)_$(curl -ssL https://api.github.com/repos/${VERSION_REPO}/commits/${VERSION_BRANCH} | awk '{if ($1=="\"sha\":") {print substr($2,2,7); exit}}')_${VERSION_BRANCH}_$(/usr/local/bin/fr24feed --version)" > /.CONTAINER_VERSION && \
    /usr/local/bin/fr24feed --version > /.FR24_VERSION && \
    cat /.CONTAINER_VERSION

COPY rootfs/ /

EXPOSE 30334/tcp 8754/tcp 30003/tcp

# Add healthcheck
HEALTHCHECK --start-period=600s --interval=600s CMD /scripts/healthcheck.sh

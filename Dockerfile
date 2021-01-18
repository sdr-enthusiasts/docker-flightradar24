FROM debian:stable-slim

ARG TARGETPLATFORM
ARG BUILDPLATFORM

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEASTPORT=30005 \
    MLAT=no \
    VERBOSE_LOGGING=false

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    echo "========== Prerequisites ==========" && \
    apt-get update -y && \
    apt-get install --no-install-recommends -y \
        bc \
        binutils \
        ca-certificates \
        curl \
        expect \
        file \
        gnupg \
        net-tools \
        procps \
        xmlstarlet \
        && \
    echo "========== Deploying s6-overlay ==========" && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    echo "========== Deploying fr24feed ==========" && \
    /scripts/deploy_fr24feed.sh && \
    echo "========== Clean-up ==========" && \
    apt-get remove -y \
        curl \
        file \
        gnupg \
        xmlstarlet \
        && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /src && \
    fr24feed --version > /CONTAINER_VERSION && \
    cat /CONTAINER_VERSION

EXPOSE 30334/tcp 8754/tcp 30003/tcp

ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh

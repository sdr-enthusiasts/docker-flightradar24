FROM ghcr.io/sdr-enthusiasts/docker-baseimage:qemu

ARG TARGETPLATFORM
ARG BUILDPLATFORM

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEASTPORT=30005 \
    MLAT=no \
    VERBOSE_LOGGING=false

COPY rootfs/ /

# NEW STUFF BELOW
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # 'expect' required for signup
    KEPT_PACKAGES+=(expect) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # Download fr24feed arm binary
    curl \
        --location \
        -o "/tmp/fr24feed_armhf.tgz" \
        "https://repo-feed.flightradar24.com/rpi_binaries/fr24feed_1.0.29-7_armhf.tgz" \
        && \
    # Extract fr24feed
    tar xvf /tmp/fr24feed_armhf.tgz -C /tmp/ && \
    # Copy fr24feed
    cp -v /tmp/fr24feed_armhf/fr24feed /usr/local/bin/ && \
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

# OLD STUFF BELOW
# RUN set -x && \
#     echo "========== Prerequisites ==========" && \
#     apt-get update -y && \
#     apt-get install --no-install-recommends -y \
#         bc \
#         binutils \
#         ca-certificates \
#         curl \
#         expect \
#         file \
#         gnupg \
#         net-tools \
#         procps \
#         xmlstarlet \
#         && \
#     echo "========== Deploying s6-overlay ==========" && \
#     curl \
#         -o /tmp/deploy-s6-overlay.sh \
#         --location \
#         https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh \
#         && \
#     bash /tmp/deploy-s6-overlay.sh && \
#     echo "========== Deploying fr24feed ==========" && \
#     /scripts/deploy_fr24feed.sh && \
#     echo "========== Clean-up ==========" && \
#     apt-get remove -y \
#         curl \
#         file \
#         gnupg \
#         xmlstarlet \
#         && \
    

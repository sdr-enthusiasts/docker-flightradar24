FROM debian:stable-slim

ENV FR24FEED_VERSION=1.0.24-5 \
    FR24FEED_ARCH=amd64 \
    VERSION_S6OVERLAY=v1.22.1.0 \
    ARCH_S6OVERLAY=amd64 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    BEASTPORT=30005 \
    MLAT=no

# MLAT needs to be set to 'no' due to a segfault issue with fr24feed

ADD https://repo-feed.flightradar24.com/linux_x86_64_binaries/fr24feed_${FR24FEED_VERSION}_${FR24FEED_ARCH}.deb /tmp/fr24feed.deb

RUN apt-get update -y
RUN apt-get install -y binutils procps ca-certificates

RUN cd /tmp && \
    ar x /tmp/fr24feed.deb && \
    tar xzvf data.tar.gz && \
    find /tmp -name .DS_Store -exec rm {} \; && \
    mv -v /tmp/usr/bin/* /usr/bin/ && \
    mv -v /tmp/usr/lib/fr24 /usr/lib/ && \
    mv -v /tmp/usr/share/fr24 /usr/share/ && \
    touch /var/log/fr24feed.log

# Install s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/${VERSION_S6OVERLAY}/s6-overlay-${ARCH_S6OVERLAY}.tar.gz /tmp/s6-overlay.tar.gz
RUN tar -xzf /tmp/s6-overlay.tar.gz -C /

COPY etc/ /etc/

EXPOSE 30334/tcp 8754/tcp 30003/tcp

ENTRYPOINT [ "/init" ]

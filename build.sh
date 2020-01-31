#!/bin/sh

VERSION=1.0.24
ARCH=`uname -m`
IMAGE=mikenye/fr24feed

# Make architecture names match docker 'standards' (https://docs.docker.com/docker-for-mac/multi-arch/)
if [ ${ARCH} = "aarch64" ]; then
    ARCH="arm64v8"
fi
if [ ${ARCH} = "x86_64" ]; then
    ARCH="amd64"
fi
if [ ${ARCH} = "armv7l" ]; then
    ARCH="arm32v7"
fi

# Check if target dockerfile exists
if [ -f "Dockerfile.${ARCH}" ]; then
    # Build
    echo Building from Dockerfile.${ARCH}
    docker build -f Dockerfile.${ARCH} -t ${IMAGE}:${VERSION}-${ARCH} .
else
    echo Target file Dockerfile.${ARCH} does not exist!
fi


#!/bin/bash

REPO=mikenye
IMAGE=fr24feed

export DOCKER_CLI_EXPERIMENTAL="enabled"

# arm32v7 - build temp image to get versions
echo "========== Building arm32v7 =========="
docker context use arm32v7
docker build -t "${REPO}/${IMAGE}:arm32v7_build" .
FR24IMAGEVERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:arm32v7_build" /VERSION)
echo "Tagging ${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker tag "${REPO}/${IMAGE}:arm32v7_build" "${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker tag "${REPO}/${IMAGE}:arm32v7_build" "${REPO}/${IMAGE}:latest_armhf"
echo "Pushing ${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker push "${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
echo "Pushing ${REPO}/${IMAGE}:latest_armhf"
docker push "${REPO}/${IMAGE}:latest_armhf"

# x86_64 - build temp image to get versions
echo "========== Building x86_64 =========="
docker context use x86_64
docker build -t "${REPO}/${IMAGE}:x86_64_build" .
FR24IMAGEVERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:x86_64_build" /VERSION)
echo "Tagging ${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker tag "${REPO}/${IMAGE}:x86_64_build" "${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker tag "${REPO}/${IMAGE}:x86_64_build" "${REPO}/${IMAGE}:latest_amd64"
echo "Pushing ${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker push "${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
echo "Pushing ${REPO}/${IMAGE}:latest_amd64"
docker push "${REPO}/${IMAGE}:latest_amd64"

# multiarch buildx
echo "========== Buildx multiarch =========="
docker buildx use homecluster
docker buildx build -t "${REPO}/${IMAGE}:latest" --compress --push --platform linux/amd64,linux/arm/v7 .

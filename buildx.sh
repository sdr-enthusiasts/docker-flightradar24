#!/bin/bash

REPO=mikenye
IMAGE=fr24feed
PLATFORMS="linux/amd64,linux/arm/v7,linux/arm64"

docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

# arm32v7 - build temp image to get versions
echo "========== Building arm32v7 =========="
docker context use arm32v7
docker build --no-cache -t "${REPO}/${IMAGE}:arm32v7_build" .
FR24IMAGEVERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:arm32v7_build" /VERSION)
echo "Tagging ${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker tag "${REPO}/${IMAGE}:arm32v7_build" "${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker tag "${REPO}/${IMAGE}:arm32v7_build" "${REPO}/${IMAGE}:latest_armhf"
echo "Pushing ${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker push "${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
echo "Pushing ${REPO}/${IMAGE}:latest_armhf"
docker push "${REPO}/${IMAGE}:latest_armhf"

# arm64 - build temp image to get versions
echo "========== Building arm64 =========="
docker context use arm64
docker build --no-cache -t "${REPO}/${IMAGE}:arm64_build" .
FR24IMAGEVERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:arm64_build" /VERSION)
echo "Tagging ${REPO}/${IMAGE}:${FR24IMAGEVERSION}"
docker tag "${REPO}/${IMAGE}:arm64_build" "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_arm64"
docker tag "${REPO}/${IMAGE}:arm64_build" "${REPO}/${IMAGE}:latest_arm64"
echo "Pushing ${REPO}/${IMAGE}:${FR24IMAGEVERSION}_arm64"
docker push "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_arm64"
echo "Pushing ${REPO}/${IMAGE}:latest_arm64"
docker push "${REPO}/${IMAGE}:latest_arm64"

# x86_64 - build temp image to get versions
echo "========== Building x86_64 =========="
docker context use x86_64
docker build --no-cache -t "${REPO}/${IMAGE}:x86_64_build" .
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
docker context use x86_64
docker buildx use homecluster
docker buildx build --no-cache -t "${REPO}/${IMAGE}:latest" --compress --push --platform "${PLATFORMS}" .

# BUILD NOHEALTHCHECK VERSIONS
# Modify dockerfile to remove healthcheck
sed '/^HEALTHCHECK /d' < Dockerfile > Dockerfile.nohealthcheck

# Build & push latest
docker buildx build -f Dockerfile.nohealthcheck -t ${REPO}/${IMAGE}:latest_nohealthcheck --compress --push --platform "${PLATFORMS}" .

# arm32v7 - build temp image to get versions
echo "========== Building arm32v7 =========="
docker context use arm32v7
docker build -t "${REPO}/${IMAGE}:arm32v7_build_nohealthcheck" .
FR24IMAGEVERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:arm32v7_build_nohealthcheck" /VERSION)
echo "Tagging ${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
docker tag "${REPO}/${IMAGE}:arm32v7_build" "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
docker tag "${REPO}/${IMAGE}:arm32v7_build" "${REPO}/${IMAGE}:latest_armhf_nohealthcheck"
echo "Pushing ${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
docker push "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
echo "Pushing ${REPO}/${IMAGE}:latest_armhf_nohealthcheck"
docker push "${REPO}/${IMAGE}:latest_armhf_nohealthcheck"

# arm64 - build temp image to get versions
echo "========== Building arm64 =========="
docker context use arm64
docker build -t "${REPO}/${IMAGE}:arm64_build_nohealthcheck" .
FR24IMAGEVERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:arm64_build_nohealthcheck" /VERSION)
echo "Tagging ${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
docker tag "${REPO}/${IMAGE}:arm64_build" "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_arm64_nohealthcheck"
docker tag "${REPO}/${IMAGE}:arm64_build" "${REPO}/${IMAGE}:latest_arm64_nohealthcheck"
echo "Pushing ${REPO}/${IMAGE}:${FR24IMAGEVERSION}_arm64_nohealthcheck"
docker push "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_arm64_nohealthcheck"
echo "Pushing ${REPO}/${IMAGE}:latest_arm64_nohealthcheck"
docker push "${REPO}/${IMAGE}:latest_arm64_nohealthcheck"

# x86_64 - build temp image to get versions
echo "========== Building x86_64 =========="
docker context use x86_64
docker build -t "${REPO}/${IMAGE}:x86_64_build_nohealthcheck" .
FR24IMAGEVERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:x86_64_build_nohealthcheck" /VERSION)
echo "Tagging ${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
docker tag "${REPO}/${IMAGE}:x86_64_build" "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
docker tag "${REPO}/${IMAGE}:x86_64_build" "${REPO}/${IMAGE}:latest_amd64_nohealthcheck"
echo "Pushing ${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
docker push "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_nohealthcheck"
echo "Pushing ${REPO}/${IMAGE}:latest_amd64_nohealthcheck"
docker push "${REPO}/${IMAGE}:latest_amd64_nohealthcheck"


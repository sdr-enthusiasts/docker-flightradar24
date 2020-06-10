#!/bin/bash

REPO=mikenye
IMAGE=fr24feed
PLATFORMS="linux/386,linux/amd64,linux/arm/v7,linux/arm64"

docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

echo "========== Building linux/arm/v7 =========="
docker buildx build -t "${REPO}/${IMAGE}:latest_armhf" --compress --push --platform "linux/arm/v7" .
docker --context=arm32v7 pull "${REPO}/${IMAGE}:latest_armhf"
FR24IMAGEVERSION=$(docker --context=arm32v7 run --rm --entrypoint cat "${REPO}/${IMAGE}:latest_armhf" /VERSION)
docker buildx build -t "${REPO}/${IMAGE}:${FR24IMAGEVERSION}" --compress --push --platform "linux/arm/v7" .

echo "========== Building linux/arm64 =========="
docker buildx build -t "${REPO}/${IMAGE}:latest_arm64" --compress --push --platform "linux/arm64" .
docker --context=arm64 pull "${REPO}/${IMAGE}:latest_arm64"
FR24IMAGEVERSION=$(docker --context=arm64 run --rm --entrypoint cat "${REPO}/${IMAGE}:latest_arm64" /VERSION)
docker buildx build -t "${REPO}/${IMAGE}:${FR24IMAGEVERSION}_arm64" --compress --push --platform "linux/arm64" .

echo "========== Building linux/amd64 =========="
docker buildx build -t "${REPO}/${IMAGE}:latest_amd64" --compress --push --platform "linux/amd64" .
docker --context=x86_64 pull "${REPO}/${IMAGE}:latest_amd64"
FR24IMAGEVERSION=$(docker --context=x86_64 run --rm --entrypoint cat "${REPO}/${IMAGE}:latest_amd64" /VERSION)
docker buildx build -t "${REPO}/${IMAGE}:${FR24IMAGEVERSION}" --compress --push --platform "linux/amd64" .

echo "========== Building linux/386 =========="
docker buildx build -t "${REPO}/${IMAGE}:latest_i386" --compress --push --platform "linux/386" .
docker --context=x86_64 pull "${REPO}/${IMAGE}:latest_i386"
FR24IMAGEVERSION=$(docker --context=x86_64 run --rm --entrypoint cat "${REPO}/${IMAGE}:latest_i386" /VERSION)
docker buildx build -t "${REPO}/${IMAGE}:${FR24IMAGEVERSION}" --compress --push --platform "linux/386" .

# multiarch buildx
echo "========== Buildx multiarch =========="
docker context use x86_64
docker buildx use homecluster
docker buildx build -t "${REPO}/${IMAGE}:latest" --compress --push --platform "${PLATFORMS}" .

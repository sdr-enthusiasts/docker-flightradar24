#
# Docker architectures
# https://github.com/docker-library/official-images/blob/a7ad3081aa5f51584653073424217e461b72670a/bashbrew/go/vendor/src/github.com/docker-library/go-dockerlibrary/architecture/oci-platform.go#L14-L25
#

VERSION=1.0.24
IMAGE=mikenye/fr24feed

docker pull ${IMAGE}:${VERSION}-amd64
docker pull ${IMAGE}:${VERSION}-arm32v7
#docker pull ${IMAGE}:${VERSION}-arm64v8

docker manifest create --amend ${IMAGE}:${VERSION} ${IMAGE}:${VERSION}-amd64 ${IMAGE}:${VERSION}-arm32v7 #${IMAGE}:${VERSION}-arm64v8
docker manifest annotate ${IMAGE}:${VERSION} ${IMAGE}:${VERSION}-amd64 --os linux --arch amd64
docker manifest annotate ${IMAGE}:${VERSION} ${IMAGE}:${VERSION}-arm32v7 --os linux --arch arm --variant v7
#docker manifest annotate ${IMAGE}:${VERSION} ${IMAGE}:${VERSION}-arm64v8 --os linux --arch arm64 --variant v8
docker manifest push --purge ${IMAGE}:${VERSION}

docker tag ${IMAGE}:${VERSION}-amd64 ${IMAGE}:latest-amd64
docker tag ${IMAGE}:${VERSION}-arm32v7 ${IMAGE}:latest-arm32v7
#docker tag ${IMAGE}:${VERSION}-arm64v8 ${IMAGE}:latest-arm64v8

docker push ${IMAGE}:latest-amd64
docker push ${IMAGE}:latest-arm32v7
#docker push ${IMAGE}:latest-arm64v8

docker manifest create --amend ${IMAGE}:latest ${IMAGE}:${VERSION}-amd64 ${IMAGE}:${VERSION}-arm32v7 #${IMAGE}:${VERSION}-arm64v8
docker manifest annotate ${IMAGE}:latest ${IMAGE}:${VERSION}-amd64 --os linux --arch amd64
docker manifest annotate ${IMAGE}:latest ${IMAGE}:${VERSION}-arm32v7 --os linux --arch arm --variant v7
#docker manifest annotate ${IMAGE}:latest ${IMAGE}:${VERSION}-arm64v8 --os linux --arch arm64 --variant v8
docker manifest push --purge ${IMAGE}:latest


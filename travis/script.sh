#!/bin/bash
set -e


if [[ ! -z "${ARCH}" ]]; then
  docker build --no-cache -t lnd --build-arg "goarch=${ARCH}" "${PREFIX}/"

  if [[ -n "${TRAVIS_TAG}" ]]; then
    travis_retry timeout 5m echo "${DOCKER_PASS}" | docker login -u="${DOCKER_USER}" --password-stdin

    docker tag lnd "${SLUG}:${TRAVIS_TAG}-linux-${ARCH}"
    docker push "${SLUG}:${TRAVIS_TAG}-linux-${ARCH}"
  fi

  exit 0
fi

echo "Saving images"

LATEST_ARM="${SLUG}:${TRAVIS_TAG}-linux-arm"
LATEST_AMD64="${SLUG}:${TRAVIS_TAG}-linux-amd64"

mkdir images

docker pull ${LATEST_ARM}
docker save ${LATEST_ARM} | gzip > "images/${SLUG/\//-}-${TRAVIS_TAG}-linux-arm.tgz"

docker pull ${LATEST_AMD64}
docker save ${LATEST_AMD64} | gzip > "images/${SLUG/\//-}-${TRAVIS_TAG}-linux-amd64.tgz"

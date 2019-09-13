#!/bin/bash
set -e

# Build image for specified architecture, if specified
if [[ ! -z "${ARCH}" ]]; then
    docker build --no-cache -t lnd --build-arg "arch=${ARCH}" "${PREFIX}/"

    # Push image, if tag was specified
    if [[ -n "${TRAVIS_TAG}" ]]; then
        echo "${DOCKER_PASS}" | docker login -u="${DOCKER_USER}" --password-stdin

        docker tag lnd "${SLUG}:${TRAVIS_TAG}-${ARCH}"
        docker push "${SLUG}:${TRAVIS_TAG}-${ARCH}"
    fi

    exit 0
fi

# This happens when no ARCH was provided.  Specifically, in the deploy job.
echo "Saving images"

LATEST_ARM6="${SLUG}:${TRAVIS_TAG}-linux-armv6"
LATEST_ARM7="${SLUG}:${TRAVIS_TAG}-linux-armv7"
LATEST_ARM8="${SLUG}:${TRAVIS_TAG}-linux-armv8"
LATEST_AMD64="${SLUG}:${TRAVIS_TAG}-linux-amd64"

mkdir images

docker pull ${LATEST_ARM6}
docker save ${LATEST_ARM6} | gzip > "images/${SLUG/\//-}-${TRAVIS_TAG}-linux-armv6.tgz"

docker pull ${LATEST_ARM7}
docker save ${LATEST_ARM7} | gzip > "images/${SLUG/\//-}-${TRAVIS_TAG}-linux-armv7.tgz"

docker pull ${LATEST_ARM8}
docker save ${LATEST_ARM8} | gzip > "images/${SLUG/\//-}-${TRAVIS_TAG}-linux-armv8.tgz"

docker pull ${LATEST_AMD64}
docker save ${LATEST_AMD64} | gzip > "images/${SLUG/\//-}-${TRAVIS_TAG}-linux-amd64.tgz"

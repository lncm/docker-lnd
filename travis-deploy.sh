#!/bin/bash
set -e

image="lncm/lnd"

docker tag lnd "$image:${TRAVIS_TAG}-linux-arm"
docker push "$image:${TRAVIS_TAG}-linux-arm"

set +e
if [[ "$(docker images -q "$image:${TRAVIS_TAG}-linux-amd64" 2> /dev/null)" == "" ]]; then
    sleep 15
    echo "waiting for $image:${TRAVIS_TAG}-linux-amd64 to finish building…"
fi
set -e

echo "Pushing manifest $image:${TRAVIS_TAG}"
docker -D manifest create "$image:${TRAVIS_TAG}" \
    "$image:${TRAVIS_TAG}-linux-amd64" \
    "$image:${TRAVIS_TAG}-linux-arm"

docker manifest annotate "$image:${TRAVIS_TAG}" "$image:${TRAVIS_TAG}-linux-arm" --os linux --arch arm --variant v6
docker manifest push "$image:${TRAVIS_TAG}"


echo "Pushing manifest $image:latest"
docker -D manifest create "$image:latest" \
    "$image:${TRAVIS_TAG}-linux-amd64" \
    "$image:${TRAVIS_TAG}-linux-arm"

docker manifest annotate "$image:latest" "$image:${TRAVIS_TAG}-linux-arm" --os linux --arch arm --variant v6
docker manifest push "$image:latest"


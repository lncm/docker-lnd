#!/bin/bash
set -e

image="meedamian/lnd"
docker tag lnd "$image:linux-arm-$TRAVIS_TAG"
docker push "$image:linux-arm-$TRAVIS_TAG"

set +e
# this will probably never be necessary, as docker hub is fast and travis+qemu are **really** slow
echo "Waiting for docker hub to finish building $image:linux-amd64-$TRAVIS_TAG"

if [[ "$(docker images -q "$image:linux-amd64-$TRAVIS_TAG" 2> /dev/null)" == "" ]]; then
    sleep 15
    echo "waiting for $image:linux-amd64-$TRAVIS_TAG to finish building…"
fi
set -e

echo "Pushing manifest $image:$TRAVIS_TAG"
docker -D manifest create "$image:$TRAVIS_TAG" \
    "$image:linux-amd64-$TRAVIS_TAG" \
    "$image:linux-arm-$TRAVIS_TAG"

docker manifest annotate "$image:$TRAVIS_TAG" "$image:linux-arm-$TRAVIS_TAG" --os linux --arch arm --variant v6
docker manifest push "$image:$TRAVIS_TAG"


echo "Pushing manifest $image:latest"
docker -D manifest create "$image:latest" \
    "$image:linux-amd64-$TRAVIS_TAG" \
    "$image:linux-arm-$TRAVIS_TAG"

docker manifest annotate "$image:latest" "$image:linux-arm-$TRAVIS_TAG" --os linux --arch arm --variant v6
docker manifest push "$image:latest"


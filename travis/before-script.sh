#!/bin/bash
set -e

if [[ "${ARCH}" = "arm" ]]; then
  sed -ie 's/FROM alpine/FROM arm32v6\/alpine/g' "${PREFIX}/Dockerfile"
  echo "${PREFIX}/Dockerfile modified"
fi

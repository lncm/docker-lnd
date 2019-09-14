#!/bin/sh

set -e

ARCH=$1

PKG="github.com/lightningnetwork/lnd"
COMMIT="$(git describe --abbrev=40 --dirty)"
COMMITFLAGS="-X ${PKG}/build.Commit=${COMMIT}"

export GOOS=linux
export GOARCH="${ARCH}"

case "${ARCH}" in
arm32v6) export GOARCH=arm GOARM=6 ;;
arm32v7) export GOARCH=arm GOARM=7 ;;
esac

# NOTE: needed because of https://github.com/lightningnetwork/lnd/issues/3506
BTCWALLET=github.com/btcsuite/btcwallet
go mod edit -replace="${BTCWALLET}=${BTCWALLET}@v0.0.0-20190814023431-505acf51507f"

TAGS="autopilotrpc invoicesrpc walletrpc routerrpc watchtowerrpc"

mkdir -p /bin/

go build -v -trimpath -ldflags "${COMMITFLAGS}" -tags="${TAGS} signrpc chainrpc" -o /bin/ "${PKG}/cmd/lnd"
go build -v -trimpath -ldflags "${COMMITFLAGS}" -tags="${TAGS}"                  -o /bin/ "${PKG}/cmd/lncli"

ls -la /bin/

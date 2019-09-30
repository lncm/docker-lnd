#!/bin/sh

set -e

ARCH=$1

PKG="github.com/lightningnetwork/lnd"
COMMIT="$(git describe --abbrev=40)"
COMMITFLAGS="-w -s -buildid= -X ${PKG}/build.Commit=${COMMIT}"

export GOOS=linux

case "${ARCH}" in
arm32v6) export GOARCH=arm GOARM=6 ;;
arm32v7) export GOARCH=arm GOARM=7 ;;
*)       export GOARCH="${ARCH}"   ;;
esac

# original content
#   src: https://github.com/lightningnetwork/lnd/blob/v0.8.0-beta-rc1/release.sh#L63-L64
TAGS="autopilotrpc invoicesrpc walletrpc routerrpc watchtowerrpc"

# Added by yours truly (@lncm)
TAGS="${TAGS} neutrino wtclientrpc"

go build -v -trimpath -mod=readonly -o /go/bin/ -ldflags "${COMMITFLAGS}" -tags="${TAGS} signrpc chainrpc" "${PKG}/cmd/lnd"
go build -v -trimpath -mod=readonly -o /go/bin/ -ldflags "${COMMITFLAGS}" -tags="${TAGS}"                  "${PKG}/cmd/lncli"

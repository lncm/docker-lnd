#!/bin/sh

set -e

ARCH=$1

PKG="github.com/lightningnetwork/lnd"

# All our images are built for Linux
export GOOS=linux

# Process passed ARCH string into sth `go build` command understands
case "${ARCH}" in
arm32v6) export GOARCH=arm GOARM=6 ;;
arm32v7) export GOARCH=arm GOARM=7 ;;
*)       export GOARCH="${ARCH}"   ;;
esac


# [smaller output binaries] Disable DWARF generation, and symbol table respectively
LDFLAGS="-w -s"

# [binary version] Inject --version into the final binary
LDFLAGS="${LDFLAGS} -X ${PKG}/build.Commit=$(git describe --abbrev=40)"


# original content
#   src: https://github.com/lightningnetwork/lnd/blob/v0.7.1-beta/release.sh#L63-L64
TAGS="autopilotrpc invoicesrpc walletrpc routerrpc watchtowerrpc"

# Added by yours truly (@lncm)
TAGS="${TAGS} wtclientrpc"

# Added to make output binary static
#   ctx: https://github.com/golang/go/issues/26492
# TODO: Check if still needed after Go v1.14 release
TAGS="${TAGS} osusergo netgo static_build"

build() {
  binary_name=$1
  extra_tags=$2

  go build -v \
    -mod=readonly \
    -o /go/bin/ \
    -ldflags "${LDFLAGS}" \
    -tags="${TAGS} ${extra_tags}" \
    "${PKG}/cmd/${binary_name}"
}

build lncli
build lnd "signrpc chainrpc"

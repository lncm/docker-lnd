# lnd version to be build
ARG VERSION=v0.7.1-beta

# Target CPU archtecture of built IPFS binary
ARG ARCH=amd64

# Define default versions so that they don't have to be repreated throughout the file
ARG VER_GO=1.13
ARG VER_ALPINE=3.11

ARG EXTRA_TAGS


#
## This set of Docker stages, serves as a base for all cross-compilation targets.
#   `alpine-base` only defines `GOOS`, which is common to all other ARCH-specific stages.
#   Each supported CPU architecture defines it's own stage, which inherits from `alpine-base`, and sets up its own ENV VARs.
#
FROM golang:${VER_GO}-alpine${VER_ALPINE} AS alpine-base
ENV GOOS linux

FROM alpine-base AS amd64-alpine
ENV GOARCH amd64

FROM alpine-base AS arm64v8-alpine
ENV GOARCH arm64

FROM alpine-base AS arm32v6-alpine
ENV GOARCH arm
ENV GOARM 6

FROM alpine-base AS arm32v7-alpine
ENV GOARCH arm
ENV GOARM 7


#
## This set of Docker stages, is identical as above, except it's based on Debian, instead of Alpine.
#
FROM golang:${VER_GO}-buster AS debian-base
ENV GOOS linux

FROM debian-base AS amd64-debian
ENV GOARCH amd64

FROM debian-base AS arm64v8-debian
ENV GOARCH arm64

FROM debian-base AS arm32v6-debian
ENV GOARCH arm
ENV GOARM 6

FROM debian-base AS arm32v7-debian
ENV GOARCH arm
ENV GOARM 7



#
## TODO: Write summary of this stage
#
FROM ${ARCH}-alpine AS preparer

ARG VERSION

RUN apk add --no-cache  gnupg  git

ENV KEYBASE_USER=roasbeef
ENV KEY F8037E70C12C7A263C032508CE58F7F8E20FD9A2

# First, try to import key currently on @roasbeef's keybase account into GPG,
# Second, also try to fetch that key from keyservers (in case it's not his key, or he already discarded it…).
#   This command doesn't stop the flow on error, and
#   Key verification happens in the next step
RUN wget -qO- "https://keybase.io/${KEYBASE_USER}/pgp_keys.asc" | gpg --import && \
    for SRV in keyserver.ubuntu.com  hkp://p80.pool.sks-keyservers.net:80  ha.pool.sks-keyservers.net  keyserver.pgp.com  pgp.mit.edu; do \
        timeout 9s  gpg  --keyserver "${SRV}"  --recv-key ${KEY}  >/dev/null 2<&1 && \
            { echo "OK:  ${SRV}" && exit 0; } || \
            { echo "ERR: ${SRV} fail=$?"; } ; \
    done

RUN gpg --list-keys && \
    gpg --list-key ${KEY}


RUN mkdir -p /go/src/

ENV DIR /go/src/lnd/

# Fetch lnd source code
RUN cd /go/src/ && \
    git clone  -b "${VERSION}"  --depth=1  https://github.com/lightningnetwork/lnd

WORKDIR /go/src/lnd/

# NOTE: The fallback condition is a hack around @Roasbeef's "key hygiene".  A manual attempt at accepting expired keys
#       through git verify-tag; What can possibly go wrong? 😅
#       More: https://github.com/lightningnetwork/lnd/issues/3507#issuecomment-532414524
RUN git verify-tag "${VERSION}" || \
    { git verify-tag --raw "${VERSION}" 2>&1 | grep EXPKEYSIG && echo "Accepting valid signature with an expired key!"; }

# NOTE: context: https://github.com/lightningnetwork/lnd/issues/3506
RUN go mod edit \
    -go=1.13 \
    -replace="github.com/btcsuite/btcwallet=github.com/btcsuite/btcwallet@v0.0.0-20190814023431-505acf51507f"

RUN go mod tidy

RUN git diff


#
## TODO: Write summary of this stage
#
FROM ${ARCH}-alpine AS alpine-builder

ENV PKG=github.com/lightningnetwork/lnd

# original content
#   src: https://github.com/lightningnetwork/lnd/blob/v0.7.1-beta/release.sh#L63-L64
ENV TAGS="autopilotrpc invoicesrpc walletrpc routerrpc watchtowerrpc"

# Added to make output binary static
#   ctx: https://github.com/golang/go/issues/26492
ENV TAGS="${TAGS} osusergo netgo static_build"

# Added by yours truly (@lncm)
ENV TAGS="${TAGS} wtclientrpc"


# Install dependencies
RUN apk add --no-cache \
    libc-dev \
    git \
    gcc

RUN mkdir -p /go/src/

COPY  --from=preparer  /go/src/  /go/src/

WORKDIR /go/src/lnd/

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
#   queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

RUN env && \
    go version && \
    go env

RUN export LD="-w -s -X ${PKG}/build.Commit=$(git describe --abbrev=40) -buildid="; \
    echo ${PKG} ${LD} ${TAGS} && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS} signrpc chainrpc" \
        -o /go/bin/ \
        "${PKG}/cmd/lnd" && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS}" \
        -o /go/bin/ \
        "${PKG}/cmd/lncli"



#
## TODO: Write summary of this stage
#
# This stage builds lnd in a Debian environment
# NOTE: Comments that would be identical to Alpine stage skipped for brevity
FROM ${ARCH}-debian AS debian-builder

ENV PKG=github.com/lightningnetwork/lnd

# original content
#   src: https://github.com/lightningnetwork/lnd/blob/v0.7.1-beta/release.sh#L63-L64
ENV TAGS="autopilotrpc invoicesrpc walletrpc routerrpc watchtowerrpc"

# Added to make output binary static
#   ctx: https://github.com/golang/go/issues/26492
ENV TAGS="${TAGS} osusergo netgo static_build"

# Added by yours truly (@lncm)
ENV TAGS="${TAGS} wtclientrpc"

RUN apt-get update \
    && apt-get -y install \
        file \
        git

RUN mkdir -p /go/src/

COPY  --from=preparer  /go/src/lnd/  /go/src/lnd/

WORKDIR /go/src/lnd/

ENV GODEBUG netdns=cgo

RUN env && \
    go version && \
    go env

RUN export LD="-w -s -X ${PKG}/build.Commit=$(git describe --abbrev=40) -buildid="; \
    echo ${PKG} ${LD} ${TAGS} && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS} signrpc chainrpc" \
        -o /go/bin/ \
        "${PKG}/cmd/lnd" && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS}" \
        -o /go/bin/ \
        "${PKG}/cmd/lncli"


#
## TODO: describe this stage
#
FROM alpine:${VER_ALPINE} AS cross-check

# Install utilities used later
RUN apk add --no-cache \
    ca-certificates \
    file \
    upx

RUN mkdir -p  /bin  /alpine  /debian

# Copy binaries from all builds
COPY  --from=alpine-builder  /go/bin/*  /alpine/
COPY  --from=debian-builder  /go/bin/*  /debian/

# Print binary info PRIOR comparison
RUN sha256sum   /debian/*  /alpine/*
RUN file        /debian/*  /alpine/*
RUN du          /debian/*  /alpine/*

# Compare both built binaries
RUN diff -q  /alpine/lnd   /debian/lnd \
 && diff -q  /alpine/lncli /debian/lncli

# Print binary info PRIOR compression
RUN sha256sum   /alpine/*
RUN file        /alpine/*
RUN du          /alpine/*

# Compress binaries, and be verbose about it
RUN upx -v  /alpine/lnd  /alpine/lncli

# Print binary info PAST compression
RUN sha256sum   /alpine/*
RUN file        /alpine/*
RUN du          /alpine/*

# If all are identical, proceed to move the binary into
RUN mv  /alpine/*  /bin/


#
## TODO: describe this stage
#
# Start a new, final image
FROM alpine:${VER_ALPINE} AS final

LABEL maintainer="Damian Mee (@meeDamian)"

COPY --from=cross-check /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binaries from the builder image.
COPY  --from=cross-check  /bin/lnd    /bin/
COPY  --from=cross-check  /bin/lncli  /bin/

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (rest, p2p, rpc respectively).
EXPOSE  8080  9735  10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]

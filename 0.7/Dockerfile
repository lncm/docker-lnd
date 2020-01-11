# lnd version to be build
ARG VERSION=v0.7.1-beta

# Target CPU archtecture of built IPFS binary
ARG ARCH=amd64

# Define default versions so that they don't have to be repreated throughout the file
ARG VER_GO=1.13
ARG VER_ALPINE=3.11

#
## The below ARGs are here just to avoid repetition, these are (probably) not user-changeable
#
ARG PKG=github.com/lightningnetwork/lnd

# original content
#   src: https://github.com/lightningnetwork/lnd/blob/v0.7.1-beta/release.sh#L63-L64
ARG TAGS_BASE="autopilotrpc invoicesrpc walletrpc routerrpc watchtowerrpc"
ARG TAGS_LND="signrpc chainrpc"

# Added to make output binary static
#   ctx: https://github.com/golang/go/issues/26492
ARG TAGS_STATIC="osusergo netgo static_build"

# Added by yours truly (@lncm)
ARG TAGS_EXTRA="wtclientrpc"



#
## The pairs of Docker stages below define Go Environment necessary for cross-compilation on
#   two different base images: Alpine, and Debian.  Later build stages can be started as:
#
#   `FROM ${ARCH}-debian`  or
#   `FROM ${ARCH}-alpine`
#
## Stage defining Alpine environment
FROM golang:${VER_GO}-alpine${VER_ALPINE} AS alpine-base

ARG PKG
ARG TAGS_BASE
ARG TAGS_STATIC
ARG TAGS_EXTRA

ENV TAGS="${TAGS_BASE} ${TAGS_STATIC} ${TAGS_EXTRA}"

ENV GOOS=linux

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
#   queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo



## Stage defining Debian environment
FROM golang:${VER_GO}-buster AS debian-base

ARG PKG
ARG TAGS_BASE
ARG TAGS_STATIC
ARG TAGS_EXTRA

ENV TAGS="${TAGS_BASE} ${TAGS_STATIC} ${TAGS_EXTRA}"

ENV GOOS=linux

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
#   queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo



FROM alpine-base AS amd64-alpine
ENV GOARCH=amd64

FROM debian-base AS amd64-debian
ENV GOARCH=amd64


FROM alpine-base AS arm64v8-alpine
ENV GOARCH=arm64

FROM debian-base AS arm64v8-debian
ENV GOARCH=arm64


FROM alpine-base AS arm32v7-alpine
ENV GOARCH=arm  GOARM=7

FROM debian-base AS arm32v7-debian
ENV GOARCH=arm  GOARM=7


FROM alpine-base AS arm32v6-alpine
ENV GOARCH=arm  GOARM=6

FROM debian-base AS arm32v6-debian
ENV GOARCH=arm  GOARM=6






#
## This stage fetches, and verifies the source code, as well as applies necessary fixes
#
FROM golang:${VER_GO}-alpine${VER_ALPINE} AS preparer

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

# Show all differences applied on top of upstream
RUN git diff



#
## This stage builds `lnd` & `lncli` in Alpine environment
#
FROM ${ARCH}-alpine AS alpine-builder

ARG TAGS_LND

RUN apk add --no-cache  libc-dev  git  gcc

RUN mkdir -p /go/src/

COPY  --from=preparer /go/src/  /go/src/

WORKDIR /go/src/lnd/

RUN env && \
    go version && \
    go env

RUN export LD="-w -s -X ${PKG}/build.Commit=$(git describe --abbrev=40)"; \
    echo "Building with ldflags: '${LD}'" && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS} ${TAGS_LND}" \
        -o /go/bin/ \
        "${PKG}/cmd/lnd" && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS}" \
        -o /go/bin/ \
        "${PKG}/cmd/lncli"



#
## This stage builds `lnd` & `lncli` in Debian environment
#
# NOTE: Comments that would be identical to Alpine stage skipped for brevity
FROM ${ARCH}-debian AS debian-builder

ARG TAGS_LND

RUN apt-get update  &&  apt-get -y install  file  git

RUN mkdir -p /go/src/

COPY  --from=preparer /go/src/lnd/  /go/src/lnd/

WORKDIR /go/src/lnd/

RUN env && \
    go version && \
    go env

RUN export LD="-w -s -X ${PKG}/build.Commit=$(git describe --abbrev=40)"; \
    echo "Building with ldflags: '${LD}'" && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS} ${TAGS_LND}" \
        -o /go/bin/ \
        "${PKG}/cmd/lnd" && \
    go build -v  -trimpath  -mod=readonly \
        -ldflags="${LD}"  -tags="${TAGS}" \
        -o /go/bin/ \
        "${PKG}/cmd/lncli"


#
## This stage fetches built binaries from build stages, compares them, and if they're identical puts compressed binaries to `/bin/`
#
FROM alpine:${VER_ALPINE} AS cross-check

# Install utilities used later
RUN apk add --no-cache  ca-certificates  file  upx

RUN mkdir -p  /bin  /alpine  /debian

# Copy binaries from build stages
COPY  --from=alpine-builder /go/bin/*  /alpine/
COPY  --from=debian-builder /go/bin/*  /debian/

# Print binary info PRIOR comparison & compression
RUN sha256sum   /debian/*  /alpine/*
RUN file        /debian/*  /alpine/*
RUN du          /debian/*  /alpine/*

# Compare both built binaries
RUN diff -q  /alpine/lnd   /debian/lnd \
 && diff -q  /alpine/lncli /debian/lncli

# Compress binaries, and be verbose about it
RUN upx -v  /alpine/lnd  /alpine/lncli

# Print binary info AFTER compression
RUN sha256sum   /alpine/*
RUN file        /alpine/*
RUN du          /alpine/*

# If all are identical, proceed to move the binary into a more standard `/bin/`
RUN mv  /alpine/*  /bin/


#
## This is the final image that gets shipped to Docker Hub
#
FROM ${ARCH}/alpine:${VER_ALPINE} AS final

LABEL maintainer="Damian Mee (@meeDamian)"

COPY --from=cross-check /etc/ssl/certs/ca-certificates.crt  /etc/ssl/certs/

# Copy binaries from the builder image.
COPY  --from=cross-check /bin/lnd    /bin/
COPY  --from=cross-check /bin/lncli  /bin/

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (rest, p2p, rpc respectively).
EXPOSE  8080  9735  10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]

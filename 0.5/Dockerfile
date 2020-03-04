# This Dockerfile builds lnd v0.5.x on Alpine, and copies the result binaries to the `final` stage

# lnd version to be build
ARG VERSION=v0.5.2-beta

# Target CPU archtecture of built lnd binary
ARG ARCH

# Define default versions so that they don't have to be repreated throughout the file
ARG VER_GO=1.14
ARG VER_ALPINE=3.11

ARG USER=lnd
ARG DIR=/data/


#
## This stage fetches and verifies source code, and applies necessary fixes
#
FROM golang:${VER_GO}-alpine${VER_ALPINE} AS preparer

ARG VERSION

RUN apk add --no-cache  gnupg  git

ENV KEYS F8037E70C12C7A263C032508CE58F7F8E20FD9A2

# Try to fetch keys from keyservers listed below.  On first success terminate with `exit 0`.  If loop is not interrupted,
#   it means all attempts failed, and `exit 1` is called.
RUN for srv in  keyserver.ubuntu.com  hkp://p80.pool.sks-keyservers.net:80  ha.pool.sks-keyservers.net  keyserver.pgp.com  pgp.mit.edu; do \
        timeout 9s  gpg  --keyserver "${srv}"  --recv-keys ${KEYS}  >/dev/null 2<&1 && \
            { echo "OK:  ${srv}" && exit 0; } || \
            { echo "ERR: ${srv} fail=$?"; } ; \
    done && exit 1

# This should print the same key twice
RUN gpg --list-keys && \
    gpg --list-keys ${KEYS}

RUN mkdir -p /go/src/

# Fetch lnd source code
RUN cd /go/src/ && \
    git clone  -b "${VERSION}"  --depth=1  https://github.com/lightningnetwork/lnd .

WORKDIR /go/src/

## Verify that git tag contains a valid signature
#   NOTE: The fallback condition is a hack around @Roasbeef's "key hygiene".  A manual attempt at accepting expired keys
#       through git verify-tag; What can possibly go wrong? 😅
#       More: https://github.com/lightningnetwork/lnd/issues/3507#issuecomment-532414524
RUN git verify-tag "${VERSION}" || \
    { git verify-tag --raw "${VERSION}" 2>&1 | grep EXPKEYSIG && echo "Accepting valid signature with an expired key!"; }

# Override versions with themselves just in a different format…
RUN go mod edit \
    -replace github.com/btcsuite/btcd=github.com/btcsuite/btcd@ed77733ec07dfc8a513741138419b8d9d3de9d2d \
    -replace github.com/coreos/bbolt=github.com/coreos/bbolt@7ee3ded59d4835e10f3e7d0f7603c42aa5e83820 \
    -replace github.com/btcsuite/btcwallet=github.com/btcsuite/btcwallet@284e2e0e696e

RUN go mod tidy

# Show all differences applied on top of upstream
RUN git diff



#
## This stage builds `lnd` & `lncli` in Alpine environment
#
#   NOTE: Separation into these stages is not necessary here, but it's done for consistency
FROM preparer AS builder

# Provided by Docker by default
ARG TARGETVARIANT

# These two should only be set for cross-compilation
ARG GOARCH
ARG GOARM

# Only set GOOS if GOARCH is set
ENV GOOS ${GOARCH:+linux}

# If GOARM is not set, but TARGETVARIANT is set - hardcode GOARM to 6
ENV GOARM ${GOARM:-${TARGETVARIANT:+6}}

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
#   queries required to connect to linked containers succeed.
ENV GODEBUG "netdns=cgo"

RUN apk add --no-cache alpine-sdk \
    gcc \
    ca-certificates \
    upx

RUN env && go version && go env

# Build the binaries
RUN make install

# Move arm[64] binaries to the "standard" location, for ease of copying in the next stage
RUN if [ -d /go/bin/linux_* ]; then \
        mv    /go/bin/linux_*/*  /go/bin/  && \
        rmdir /go/bin/linux_*    ; \
    fi

# Compress, and be verbose about it
RUN upx -v /go/bin/*



#
## This stage is used to generate /etc/{group,passwd,shadow} files & avoid RUN-ing commands in the `final` layer,
#   which would break cross-compiled images.
#
FROM alpine:${VER_ALPINE} AS perms

ARG USER
ARG DIR

# NOTE: Default GID == UID == 1000
RUN adduser --disabled-password \
            --home ${DIR} \
            --gecos "" \
            ${USER}

# Needed to prevent `VOLUME ${DIR}/.lnd/` creating it with `root` as owner
USER ${USER}
RUN mkdir -p ${DIR}/.lnd/



#
## This is the final image that gets shipped to Docker Hub
#
# NOTE: `${ARCH:+${ARCH}/}` - if ARCH is set, append `/` to it, leave it empty otherwise
FROM ${ARCH:+${ARCH}/}alpine:${VER_ALPINE} AS final

ARG USER
ARG DIR

LABEL maintainer="Damian Mee (@meeDamian)"

# Copy only the relevant parts from the `perms` image
COPY  --from=perms /etc/group /etc/passwd /etc/shadow  /etc/

# From `perms`, copy *the contents* of `${DIR}` (ie. `.lnd/`), and set correct owner for destination `${DIR}`
COPY  --from=perms --chown=${USER}:${USER} ${DIR}  ${DIR}

#
COPY  --from=builder /etc/ssl/certs/ca-certificates.crt  /etc/ssl/certs/

# Copy binaries from the builder image
COPY  --from=builder /go/bin/lnd /go/bin/lncli  /usr/local/bin/

USER ${USER}

# Expose volume containing all `lnd` data
VOLUME ${DIR}/.lnd/

# Expose lnd ports (rest, p2p, rpc respectively)
EXPOSE  8080  9735  10009

# Specify the start command and entrypoint as the lnd daemon
ENTRYPOINT ["lnd"]

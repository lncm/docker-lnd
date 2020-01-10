# lnd version to be build
ARG VERSION=v0.5.2-beta

# Target CPU archtecture of built IPFS binary
ARG ARCH=amd64

# Define default versions so that they don't have to be repreated throughout the file
ARG VER_GO=1.13
ARG VER_ALPINE=3.11


#
## This set of Docker stages, serves as a base for all cross-compilation targets.
#   `go-base` only defines `GOOS`, which is common to all other ARCH-specific stages.
#   Each supported CPU architecture defines it's own stage, which inherits from `go-base`, and sets up its own ENV VARs.
#
FROM golang:${VER_GO}-alpine${VER_ALPINE} AS go-base
ENV GOOS linux

FROM go-base AS amd64
ENV GOARCH amd64

FROM go-base AS arm64v8
ENV GOARCH arm64

FROM go-base AS arm32v6
ENV GOARCH arm
ENV GOARM 6

FROM go-base AS arm32v7
ENV GOARCH arm
ENV GOARM 7


FROM ${ARCH} AS builder

ARG VERSION

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies
RUN apk add --no-cache alpine-sdk \
    findutils \
    git \
    gnupg \
    gcc \
    ca-certificates \
    upx

# Expired @roasbeef GPG key
ENV KEY F8037E70C12C7A263C032508CE58F7F8E20FD9A2

# Try to fetch keys from keyservers listed below.  On first success terminate with `exit 0`.  If loop is not interrupted,
#   it means all attempts failed, and `exit 1` is called.
RUN for SRV in  keyserver.ubuntu.com  hkp://p80.pool.sks-keyservers.net:80  ha.pool.sks-keyservers.net  keyserver.pgp.com  pgp.mit.edu; do \
        timeout 9s  gpg  --keyserver "${SRV}"  --recv-keys ${KEY}  >/dev/null 2<&1 && \
            { echo "OK:  ${SRV}" && exit 0; } || \
            { echo "ERR: ${SRV} fail=$?"; } ; \
    done && exit 1

# This should print the same key twice
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
    { git verify-tag --raw "${VERSION}" 2>&1 | grep EXPKEYSIG && echo "Accepting expired key!"; }

# Print useful info about the environment
RUN env && \
    go version && \
    go env

# Override versions with themselves just in a different format…
RUN go mod edit \
    -replace github.com/btcsuite/btcd=github.com/btcsuite/btcd@ed77733ec07dfc8a513741138419b8d9d3de9d2d \
    -replace github.com/coreos/bbolt=github.com/coreos/bbolt@7ee3ded59d4835e10f3e7d0f7603c42aa5e83820 \
    -replace github.com/btcsuite/btcwallet=github.com/btcsuite/btcwallet@284e2e0e696e

# Fixing dependencies breaks a script in `Makefile` that extracts commit hash of btcd to be installed.
#   This `.patch` hardcodes the value of `BTCD_COMMIT` to `ed77733ec07dfc8a513741138419b8d9d3de9d2d`
COPY ./fix-btcd-commit.patch .
RUN patch < fix-btcd-commit.patch

RUN go mod tidy

# Print all source differences applied
RUN git diff

# TODO: tests don't work for some reason :(
COPY --from=lncm/bitcoind:v0.18.1  /opt/bitcoin-0.18.1/bin/bitcoind     /usr/bin/
COPY --from=lncm/bitcoind:v0.18.1  /opt/bitcoin-0.18.1/bin/bitcoin-cli  /usr/bin/

RUN make unit

# Build the binaries
RUN make install

# Move arm[64] binaries to the "standard" location, for ease of copying in the next stage
RUN if [ -d /go/bin/linux_* ]; then \
        mv    /go/bin/linux_*/*  /go/bin/  && \
        rmdir /go/bin/linux_*    ; \
    fi

# Shrink output binaries
RUN upx -v /go/bin/*


# Start a new, final image
FROM ${ARCH}/alpine:${VER_ALPINE} AS final

LABEL maintainer="Damian Mee (@meeDamian)"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binaries from the builder image.
COPY --from=builder /go/bin/lnd     /usr/bin/
COPY --from=builder /go/bin/lncli   /usr/bin/

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (rest, p2p, rpc respectively).
EXPOSE  8080  9735  10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]

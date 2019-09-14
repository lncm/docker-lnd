FROM golang:1.13-alpine3.10 AS preparer

RUN apk add --no-cache \
    gnupg \
    git

ENV TAG v0.7.1-beta
ENV FINGERPRINT F8037E70C12C7A263C032508CE58F7F8E20FD9A2

RUN mkdir -p /go/src/

# Fetch lnd source code
RUN cd /go/src/ \
    && git clone -b ${TAG} --depth 1 https://github.com/lightningnetwork/lnd

WORKDIR /go/src/lnd/

# Import @roastbeef's key
RUN wget -qO - https://keybase.io/roasbeef/pgp_keys.asc | gpg --import \
    \
    # Make sure we have the right key
    && gpg --list-keys ${FINGERPRINT} \
    \
    # Verify that pulled release has been signed by the only key we've added
    # TODO: nuke the `|| true` when https://github.com/lightningnetwork/lnd/issues/3507 is resolved
    && { git verify-tag ${TAG} || true; }

# TODO: nuke after https://github.com/lightningnetwork/lnd/issues/3506 is resolved
RUN go mod edit -replace="github.com/btcsuite/btcwallet=github.com/btcsuite/btcwallet@v0.0.0-20190814023431-505acf51507f"

# NOTE: needed to have deterministic builds
RUN go mod edit -go=1.13

RUN go mod tidy

RUN git diff go.mod go.sum

COPY ./build.sh .



FROM golang:1.13-alpine3.10 AS alpine-builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
#   queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies
RUN apk add --no-cache \
    libc-dev \
    git \
    gcc

RUN mkdir -p /go/src/

COPY  --from=preparer  /go/src/lnd/  /go/src/lnd/

WORKDIR /go/src/lnd/

ARG goarch=amd64

RUN ./build.sh "${goarch}"



# This stage builds lnd in a Debian environment
# NOTE: Comments that would be identical to Alpine stage skipped for brevity
FROM golang:1.13-buster AS debian-builder

RUN apt-get update \
    && apt-get -y install \
        make \
        file \
        git

RUN mkdir -p /go/src/

COPY  --from=preparer  /go/src/lnd/  /go/src/lnd/

WORKDIR /go/src/lnd/

ARG goarch=amd64

RUN ./build.sh "${goarch}"




FROM alpine:3.10 AS cross-check

# Install utilities used later
RUN apk add --no-cache \
    ca-certificates \
    file \
    upx

RUN mkdir -p  /bin  /alpine  /debian

# Copy binaries from all builds
COPY  --from=alpine-builder  /go/bin/*  /alpine/
COPY  --from=debian-builder  /go/bin/*  /debian/

# Compare both built binaries
RUN diff -q  /alpine/lnd /debian/lnd \
    && diff -q  /alpine/lncli /debian/lncli

# Print binary info PRIOR compression
RUN sha256sum   /alpine/*
RUN file        /alpine/*
RUN du          /alpine/*

# Compress binary, and be verbose about it
RUN upx -v  /alpine/lnd  /alpine/lncli

# Print binary info PAST compression
RUN sha256sum   /alpine/*
RUN file        /alpine/*
RUN du          /alpine/*

# If all are identical, proceed to move the binary into
RUN mv /alpine/* /bin/



# Start a new, final image
FROM alpine:3.10 AS final

LABEL maintainer="Damian Mee (@meeDamian)"

COPY --from=cross-check /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binaries from the builder image.
COPY  --from=cross-check  /bin/lnd    /bin/
COPY  --from=cross-check  /bin/lncli  /bin/

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (rest, p2p, rpc respectively).
EXPOSE 8080 9735 10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]
CMD ["lnd"]

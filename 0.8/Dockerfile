FROM golang:1.13-alpine3.10 AS preparer

RUN apk add --no-cache \
    gnupg \
    git

ENV KEYS F8037E70C12C7A263C032508CE58F7F8E20FD9A2 \
         2C95FE66287126FB866FBC8D6DF57B9F9514972F

# Try to fetch keys from keyservers listed below.  On first success terminate with `exit 0`.  If loop is not interrupted,
#   it means all attempts failed, and `exit 1` is called.
RUN for SRV in hkp://p80.pool.sks-keyservers.net:80  ha.pool.sks-keyservers.net  keyserver.pgp.com  pgp.mit.edu; do \
        timeout 9s  gpg  --keyserver "${SRV}"  --recv-keys ${KEYS}  >/dev/null 2<&1 && \
            { echo "OK:  ${SRV}" && exit 0; } || \
            { echo "ERR: ${SRV} fail=$?"; } ; \
    done && exit 1

RUN gpg --list-keys

RUN mkdir -p /go/src/

ENV TAG v0.8.0-beta-rc1
ENV DIR /go/src/lnd/

# Fetch lnd source code
RUN cd /go/src/ && \
    git clone  -b "${TAG}"  --depth=1  https://github.com/lightningnetwork/lnd

WORKDIR /go/src/lnd/

# NOTE: The second part is a hack around @Roasbeef's "key hygiene".  A manual attempt at accepting expired keys through
#       git verify-tag; What can possibly go wrong? 😅
#       More: https://github.com/lightningnetwork/lnd/issues/3507#issuecomment-532414524
RUN git verify-tag "${TAG}" || \
    { git verify-tag --raw "${TAG}" 2>&1 | grep EXPKEYSIG && echo "Accepting expired key!"; }

## TODO: nuke after https://github.com/lightningnetwork/lnd/issues/3506 is resolved
#RUN go mod edit -replace="github.com/btcsuite/btcwallet=github.com/btcsuite/btcwallet@v0.0.0-20190814023431-505acf51507f"

# NOTE: needed to have deterministic builds
RUN go mod edit -go=1.13

#RUN go mod tidy

#RUN git diff go.mod go.sum

COPY ./build.sh .

# TODO:  verify hash of ./build.sh file



FROM golang:1.13-alpine3.10 AS alpine-builder

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
ARG goarch=amd64

RUN go version
RUN ./build.sh "${goarch}"



# This stage builds lnd in a Debian environment
# NOTE: Comments that would be identical to Alpine stage skipped for brevity
FROM golang:1.13-buster AS debian-builder

RUN apt-get update \
    && apt-get -y install \
        file \
        git

RUN mkdir -p /go/src/

COPY  --from=preparer  /go/src/lnd/  /go/src/lnd/

WORKDIR /go/src/lnd/

ENV GODEBUG netdns=cgo
ARG goarch=amd64

RUN go version
RUN ./build.sh "${goarch}"




FROM alpine:3.10 AS cross-check

# Install utilities used later
RUN apk add --no-cache \
    ca-certificates \
    file \
    upx \
    colordiff \
    bash


RUN mkdir -p  /bin  /alpine  /debian

# Copy binaries from all builds
COPY  --from=alpine-builder  /go/bin/*  /alpine/
COPY  --from=debian-builder  /go/bin/*  /debian/

#SHELL ["/bin/bash", "-c"]
#
#RUN xxd /debian/lncli > aaa
#RUN wc -l ./aaa
#
#RUN xxd /alpine/lncli > bbb
#RUN wc -l ./bbb
#
#RUN diff -y --suppress-common-lines --speed-large-files  ./aaa  ./bbb
#
#RUN diff <(od -An -tx1 -w1 -v /debian/lncli) \
#         <(od -An -tx1 -w1 -v /alpine/lncli)

# Print binary info PRIOR comparison
RUN sha256sum   /debian/* /alpine/*
RUN file        /debian/* /alpine/*
RUN du          /debian/* /alpine/*

# Compare both built binaries
RUN diff -q  /alpine/lnd   /debian/lnd \
 && diff -q  /{alpine,debian}/lncli

# Print binary info PRIOR compression
RUN sha256sum   /alpine/*
RUN file        /alpine/*
RUN du          /alpine/*

# Compress binary, and be verbose about it
RUN upx -v  /alpine/lnd  /alpine/lncli  /debian/lnd  /debian/lncli

# Print binary info PAST compression
#RUN sha256sum   /alpine/*
#RUN file        /alpine/*
#RUN du          /alpine/*
RUN sha256sum   /debian/* /alpine/*
RUN file        /debian/* /alpine/*
RUN du          /debian/* /alpine/*

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

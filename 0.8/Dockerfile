FROM golang:1.13-alpine3.10 AS preparer

RUN apk add --no-cache  gnupg  git

ENV TAG v0.8.0-beta


ENV KEYBASE_USER=roasbeef
ENV KEY 4AB7F8DA6FAEBB3B70B1F903BC13F65E2DC84465

# First, try to import key currently on @roasbeef's keybase account into GPG,
# Second, also try to fetch that key from keyservers (in case it's not his key, or he already discarded it…).
#   This command doesn't stop the flow on error, and
#   Key verification happens in the next step
RUN wget -qO- "https://keybase.io/${KEYBASE_USER}/pgp_keys.asc" | gpg --import && \
    for SRV in hkp://p80.pool.sks-keyservers.net:80  ha.pool.sks-keyservers.net  keyserver.pgp.com  pgp.mit.edu; do \
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
    git clone  -b "${TAG}"  --depth=1  https://github.com/lightningnetwork/lnd

WORKDIR /go/src/lnd/

# NOTE: The fallback condition is a hack around @Roasbeef's "key hygiene".  A manual attempt at accepting expired keys
#       through git verify-tag; What can possibly go wrong? 😅
#       More: https://github.com/lightningnetwork/lnd/issues/3507#issuecomment-532414524
RUN git verify-tag "${TAG}" || \
    { git verify-tag --raw "${TAG}" 2>&1 | grep EXPKEYSIG && echo "Accepting valid signature with an expired key!"; }

# NOTE: needed to have deterministic builds
RUN go mod edit -go=1.13

RUN go mod tidy

RUN git diff go.mod go.sum


ENV BUILDFILE_HASH=f9acc57138a7f777e05eaae54458b66694fab69dd5b5debedae12f9cb48ace62
COPY ./build.sh .

# Verify that the build file is what's expected
RUN echo "${BUILDFILE_HASH}  build.sh" | sha256sum -c



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

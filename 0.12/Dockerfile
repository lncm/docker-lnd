# This Dockerfile build lnd v0.11.x twice: once on Alpine, once on Debian
# If the binaries are the same, one is compressed, and copied to the `final` stage

# lnd version to be build
ARG VERSION=v0.12.0-beta

# Target CPU archtecture of built lnd binary
ARG ARCH

# Define default versions so that they don't have to be repreated throughout the file
ARG VER_GO=1.15
ARG VER_ALPINE=3.12

ARG USER=lnd
ARG DIR=/data

#
## NOTE: You should only override the ARGs below, if you know what you're doing
#
ARG PKG=github.com/lightningnetwork/lnd

# original content
#   src: https://github.com/lightningnetwork/lnd/blob/v0.12.0-beta/make/release_flags.mk#L36
ARG TAGS_BASE="autopilotrpc signrpc walletrpc chainrpc invoicesrpc watchtowerrpc"

# Added by yours truly (@lncm)
ARG TAGS_EXTRA=""


#
## This stage fetches and verifies source code, and applies necessary fixes
#
FROM golang:${VER_GO}-alpine${VER_ALPINE} AS preparer

ARG VERSION

RUN apk add --no-cache  gnupg  git

ENV KEYBASE_USER1=roasbeef
ENV KEYBASE_USER2=bitconner

# roasbeef and conner keys
ENV KEYS E4D85299674B2D31FAA1892E372CBD7633C61696 9C8D61868A7C492003B2744EE7D737B67FA592C7
# First, try to import key currently on @roasbeef's keybase account into GPG,
# Second, also try to fetch that key from keyservers (in case it's not his key, or he already discarded it…).
#   This command doesn't stop the flow on error, and
#   Key verification happens in the next step
# Import keys from keybase
RUN wget -qO- "https://keybase.io/$KEYBASE_USER1/pgp_keys.asc" | gpg --import && \
    wget -qO- "https://keybase.io/$KEYBASE_USER2/pgp_keys.asc" | gpg --import


# Print imported keys, but also ensure there's no other keys in the system
RUN gpg --list-keys | tail -n +3 | tee /tmp/keys.txt && \
    gpg --list-keys $KEYS | diff - /tmp/keys.txt

RUN mkdir -p /go/src/

# Fetch lnd source code
RUN cd /go/src/ && \
    git clone https://github.com/lightningnetwork/lnd .
RUN cd /go/src/ && git checkout "$VERSION"

WORKDIR /go/src/

## Verify that git tag contains a valid signature
#   NOTE: The fallback condition is a hack around @Roasbeef's "key hygiene".  A manual attempt at accepting expired keys
#       through git verify-tag; What can possibly go wrong? 😅
#       More: https://github.com/lightningnetwork/lnd/issues/3507#issuecomment-532414524
# RUN git verify-tag "$VERSION" || \
#     { git verify-tag --raw "$VERSION" 2>&1 | grep EXPKEYSIG && echo "Accepting valid signature with an expired key!"; }

# NOTE: needed to have deterministic builds
RUN go mod edit -go=1.15

RUN go mod tidy

# Show all differences applied on top of upstream
RUN git diff



#
## This stage builds `lnd` & `lncli` in Alpine environment
#
FROM golang:${VER_GO}-alpine${VER_ALPINE} AS alpine-builder

# Provided by Docker by default
ARG TARGETVARIANT

# These two should only be set for cross-compilation
ARG GOARCH
ARG GOARM

# Capture ARGs defined globally
ARG PKG
ARG TAGS_BASE
ARG TAGS_EXTRA

# Aggregate all tags together
ENV TAGS="$TAGS_BASE $TAGS_EXTRA"

# Only set GOOS if GOARCH is set
ENV GOOS ${GOARCH:+linux}

# If GOARM is not set, but TARGETVARIANT is set - hardcode GOARM to 6
ENV GOARM ${GOARM:-${TARGETVARIANT:+6}}

ENV LDFLAGS "-s -w -buildid="
ENV CGO_ENABLED 0

RUN apk add --no-cache  musl-dev  git  gcc

RUN mkdir -p /go/src/

COPY  --from=preparer /go/src/  /go/src/

WORKDIR /go/src/

RUN env && go version && go env

## Build `lnd` & `lncli` binaries
#   Flags explained:
#       `-v` [verbocity++] print names of compiled packages
#       `-trimpath` [reproducibility] make sure absolute paths are not included anywhere in the binary
#       `-mod=readonly` [reproducibility] do not change versions of used packages no matter what
#       `-tags` [reproducibility] tell Go to build a static binary, see more: https://github.com/golang/go/issues/26492
#       `-ldflags`
#           `-s` [size--] do not include symbol table and debug info
#           `-w` [size--] do not include DWARF symbol table
#           `-buildid` [reproducibility] while this should always be the same in our setup, clear it just-in-case
#           `-X` [info] is used to inject git-commit into the built binaries
#
#   NOTE: all of this has to happen in a single `RUN`, because it's impossible to set ENV var in Docker to
#       an output of an expression
RUN go build  -v  -trimpath  -mod=readonly  -tags="$TAGS" \
    -ldflags="$LDFLAGS \
        -X $PKG/build.Commit=$(git describe --abbrev=40) \
        -X $PKG/build.CommitHash=$(git rev-parse HEAD) \
        -X $PKG/build.GoVersion=$(go version | awk '{print $3}') \
        -X $PKG/build.RawTags=$(echo $TAGS | tr ' ' ,)" \
    -o /go/bin/  "$PKG/cmd/lnd"  "$PKG/cmd/lncli"


#
## This stage builds `lnd` & `lncli` in Debian environment
#
# NOTE: Comments that would be identical to Alpine stage skipped for brevity
FROM golang:${VER_GO}-buster AS debian-builder

ARG TARGETVARIANT
ARG GOARCH
ARG GOARM
ARG PKG
ARG TAGS_BASE
ARG TAGS_EXTRA

ENV TAGS="$TAGS_BASE $TAGS_EXTRA"
ENV GOOS ${GOARCH:+linux}
ENV GOARM ${GOARM:-${TARGETVARIANT:+6}}
ENV LDFLAGS "-s -w -buildid="
ENV CGO_ENABLED 0

RUN apt-get update  &&  apt-get -y install  file  git

RUN mkdir -p /go/src/

COPY  --from=preparer /go/src/  /go/src/

WORKDIR /go/src/

RUN env && go version && go env

RUN go build  -v  -trimpath  -mod=readonly  -tags="$TAGS" \
    -ldflags="$LDFLAGS \
        -X $PKG/build.Commit=$(git describe --abbrev=40) \
        -X $PKG/build.CommitHash=$(git rev-parse HEAD) \
        -X $PKG/build.GoVersion=$(go version | awk '{print $3}') \
        -X $PKG/build.RawTags=$(echo $TAGS | tr ' ' ,)" \
    -o /go/bin/  "$PKG/cmd/lnd"  "$PKG/cmd/lncli"



#
## This stage compares previously built binaries, and only proceeds if they are identical
#
FROM alpine:${VER_ALPINE} AS cross-check

# Install utilities used later
RUN apk add --no-cache  file  upx

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

# If identical, proceed to move the binaries into `/bin/`
RUN mv  /alpine/*  /bin/

# Compress, and be verbose about it
RUN upx -v /bin/lnd  /bin/lncli

# Print binaries' info PAST compression
RUN sha256sum   /bin/lnd  /bin/lncli
RUN file        /bin/lnd  /bin/lncli
RUN du          /bin/lnd  /bin/lncli



#
## This stage is used to generate /etc/{group,passwd,shadow} files & avoid RUN-ing commands in the `final` layer,
#   which would break cross-compiled images.
#
FROM alpine:${VER_ALPINE} AS perms

ARG USER
ARG DIR

# NOTE: Default GID == UID == 1000
RUN adduser --disabled-password \
            --home "$DIR" \
            --gecos "" \
            "$USER"

# Needed to prevent `VOLUME $DIR/.lnd/` creating it with `root` as owner
USER $USER
RUN mkdir -p "$DIR/.lnd/"



#
## This is the final image that gets shipped to Docker Hub
#
# NOTE: `${ARCH:+$ARCH/}` - if ARCH is set, append `/` to it, leave it empty otherwise
FROM ${ARCH:+$ARCH/}alpine:${VER_ALPINE} AS final

ARG USER
ARG DIR

LABEL maintainer="Damian Mee (@meeDamian)"

# Copy only the relevant parts from the `perms` image
COPY  --from=perms /etc/group /etc/passwd /etc/shadow  /etc/

# From `perms`, copy *the contents* of `$DIR` (ie. `.lnd/`), and set correct owner for destination `$DIR`
COPY  --from=perms --chown=$USER:$USER $DIR  $DIR

# Copy binaries from the cross-check stage
COPY  --from=cross-check /bin/lnd /bin/lncli  /usr/local/bin/

USER $USER

# Expose volume containing all `lnd` data
VOLUME $DIR/.lnd/

# Expose lnd ports (rest, p2p, watchtower, rpc respectively)
EXPOSE  8080  9735  9911  10009

# Specify the start command and entrypoint as the lnd daemon
ENTRYPOINT ["/usr/local/bin/lnd"]

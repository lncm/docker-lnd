FROM golang:1.12-alpine3.10 as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
#   queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies
RUN apk add --no-cache --update alpine-sdk \
    git \
    gnupg \
    gcc \
    tar \
    bash \
    ca-certificates \
    upx

ENV TAG v0.6.1-beta
ENV KEY F8037E70C12C7A263C032508CE58F7F8E20FD9A2

# Try to fetch keys from keyservers listed below.  On first success terminate with `exit 0`.  If loop is not interrupted,
#   it means all attempts failed, and `exit 1` is called.
RUN for SRV in hkp://p80.pool.sks-keyservers.net:80  ha.pool.sks-keyservers.net  keyserver.pgp.com  pgp.mit.edu; do \
        timeout 9s  gpg  --keyserver "${SRV}"  --recv-keys ${KEY}  >/dev/null 2<&1 && \
            { echo "OK:  ${SRV}" && exit 0; } || \
            { echo "ERR: ${SRV} fail=$?"; } ; \
    done && exit 1

RUN gpg --list-keys

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
    { git verify-tag --raw "${TAG}" 2>&1 | grep EXPKEYSIG && echo "Accepting expired key!"; }


ARG arch=linux-amd64
ENV LNDBUILDSYS ${arch}
ENV GO111MODULE on


# Patch for `release.sh` using `shasum` on the last line:
#   `shasum` package is not available on Alpine, and we really don't care for checksums here
RUN touch /bin/shasum && chmod +x /bin/shasum

# Build the binaries
RUN ./release.sh ${TAG}

# Uncompress binaries to the "standard" location, for ease of copying in the next stage
RUN tar -xvzf "lnd-${TAG}/lnd-${arch}-${TAG}.tar.gz"  --strip=1  -C /go/bin/

# Shrink output binaries
RUN upx -v /go/bin/*


# Start a new, final image
FROM alpine:3.10 as final

LABEL maintainer="Damian Mee (@meeDamian)"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binaries from the builder image.
COPY --from=builder /go/bin/* /bin/

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (rest, p2p, rpc respectively).
EXPOSE 8080 9735 10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]
CMD ["lnd"]

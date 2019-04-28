FROM golang:1.12-alpine3.9 as builder

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

ENV TAG v0.6-beta
ENV FINGERPRINT F8037E70C12C7A263C032508CE58F7F8E20FD9A2

ARG arch
ENV LNDBUILDSYS ${arch}

# Fetch lnd source code
RUN git clone -b ${TAG} --depth 1 https://github.com/lightningnetwork/lnd

RUN cd lnd \
    # Import @roastbeef's key
    && curl -s https://keybase.io/roasbeef/pgp_keys.asc | gpg --import \
    \
    # Make sure we have the right key
    && gpg --list-keys ${FINGERPRINT} \
    \
    # Verify that pulled release has been signed by the only key we've added
    && git verify-tag ${TAG}

# Patch for `release.sh` using `shasum` on the last line:
#   `shasum` package is not available on Alpine, and we really don't care for checksums here
RUN touch /bin/shasum && chmod +x /bin/shasum

# Build the binaries
RUN cd lnd \
    && ./release.sh ${TAG}

# Uncompress binaries to the "standard" location, for ease of copying in the next stage
RUN tar -xvzf "lnd/lnd-${TAG}/lnd-${arch}-${TAG}.tar.gz" --strip=1 -C /go/bin/

# Shrink output binaries
RUN upx -v /go/bin/*


# Start a new, final image
FROM alpine:3.9 as final

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

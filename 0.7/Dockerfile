FROM golang:1.13-alpine3.10 as builder

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

ENV TAG v0.7.1-beta
ENV FINGERPRINT F8037E70C12C7A263C032508CE58F7F8E20FD9A2

# Fetch lnd source code
RUN git clone -b ${TAG} --depth 1 https://github.com/lightningnetwork/lnd

WORKDIR lnd

# Import @roastbeef's key
RUN curl -s https://keybase.io/roasbeef/pgp_keys.asc | gpg --import \
    \
    # Make sure we have the right key
    && gpg --list-keys ${FINGERPRINT} \
    \
    # Verify that pulled release has been signed by the only key we've added
    # TODO: remove the `|| true` part as soon as https://github.com/lightningnetwork/lnd/issues/3507 is handled
    && git verify-tag ${TAG} || true

COPY ./build.sh .

ARG goarch
RUN ./build.sh "${goarch}"

#RUN exit 1
#
## Patch for `release.sh` using `shasum` on the last line:
##   `shasum` package is not available on Alpine, and we really don't care for checksums here
#RUN touch /bin/shasum && chmod +x /bin/shasum
#
## Build the binaries
#RUN cd lnd \
#    && ./release.sh ${TAG}
#
## Uncompress binaries to the "standard" location, for ease of copying in the next stage
#RUN tar -xvzf "lnd/lnd-${TAG}/lnd-${arch}-${TAG}.tar.gz" --strip=1 -C /go/bin/

# Shrink output binaries
RUN upx -v /bin/lnd /bin/lncli


# Start a new, final image
FROM alpine:3.10 as final

LABEL maintainer="Damian Mee (@meeDamian)"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy binaries from the builder image.
COPY --from=builder /bin/lnd   /bin/
COPY --from=builder /bin/lncli /bin/

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (rest, p2p, rpc respectively).
EXPOSE 8080 9735 10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]
CMD ["lnd"]

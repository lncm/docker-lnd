FROM golang:1.12-alpine3.9 as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies
RUN apk add --no-cache --update alpine-sdk \
    git \
    gnupg \
    gcc \
    ca-certificates \
    upx

ENV TAG v0.6-beta
ENV FINGERPRINT F8037E70C12C7A263C032508CE58F7F8E20FD9A2

# fetch lnd source code
RUN git clone -b ${TAG} --depth 1 https://github.com/lightningnetwork/lnd

RUN cd lnd \
    # import @roastbeef's key
    && curl -s https://keybase.io/roasbeef/pgp_keys.asc | gpg --import \

    # make sure we have the right key
    && gpg --list-keys ${FINGERPRINT} \

    # verify that pulled release has been signed by the only key we've added
    && git verify-tag ${TAG}

ARG goos
ENV GOOS ${goos}

ARG goarch
ENV GOARCH ${goarch}

ARG goarm=6
ENV GOARM ${goarm}

RUN echo "GOOS:${GOOS} GOARCH:${GOARCH} GOARM:${GOARM}"

# Build the binaries
RUN cd lnd \
    && make install

# move arm binaries to the "standard" location, for ease of copying in the next stage
RUN if [[ -d /go/bin/linux_arm/ ]]; then mv /go/bin/linux_arm/* /go/bin/; rmdir /go/bin/linux_arm/; fi

# shrink output binaries
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

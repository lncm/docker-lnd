FROM golang:1.11-alpine3.9 as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies
RUN apk add --no-cache --update alpine-sdk \
    git \
    gcc \
    ca-certificates \
    upx

# fetch lnd source code
# TODO: Add content hash validation upon source download; see lncm/docker-lnd#5
RUN git clone -b v0.5.2-beta --depth 1 https://github.com/lightningnetwork/lnd

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

# Place copy of ip where lnd expects it for NAT to work
RUN cp /sbin/ip /usr/bin/ip

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (rest, p2p, rpc respectively).
EXPOSE 8080 9735 10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]
CMD ["lnd"]

FROM golang:1.11-alpine3.9 as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies
RUN apk add --no-cache --update alpine-sdk \
    git \
    gcc \
    ca-certificates

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
    && PKG=github.com/lightningnetwork/lnd \
    && LDFLAGS="-X ${PKG}/build.Commit=$(git describe --abbrev=40 --dirty)" \
    && go build -v -ldflags "${LDFLAGS}" -o /go/bin/lnd ${PKG} \
    && go build -v -ldflags "${LDFLAGS}" -o /go/bin/lncli ${PKG}/cmd/lncli


# Start a new, final image.
FROM alpine:3.9 as final

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the binaries from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Expose lnd ports (p2p, rpc).
EXPOSE 9735 10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]
CMD ["lnd"]

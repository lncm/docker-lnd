FROM golang:alpine as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies
RUN apk add --no-cache --update alpine-sdk \
    git \
    make \
    gcc

# Build the binaries
RUN  git clone -b v0.5.2-beta-rc7 --depth 1 https://github.com/lightningnetwork/lnd \
&&  cd lnd \
&&  make \
&&  make install


# Start a new, final image.
FROM alpine as final

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Add bash and ca-certs, for quality of life and SSL-related reasons.
RUN apk --no-cache add \
    ca-certificates

# Copy the binaries from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Expose lnd ports (p2p, rpc).
EXPOSE 9735 10009

# Specify the start command and entrypoint as the lnd daemon.
ENTRYPOINT ["lnd"]
CMD ["lnd"]

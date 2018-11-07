FROM golang:1.11-alpine as builder

COPY qemu-* /usr/bin/

# Copy in the local repository to build from, and also get git
RUN apk add --no-cache git make
RUN mkdir -p /go/src/github.com/lightningnetwork
WORKDIR /go/src/github.com/lightningnetwork
RUN git clone https://github.com/lightningnetwork/lnd.git

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies and install/build lnd.
RUN cd /go/src/github.com/lightningnetwork/lnd \
&&  git checkout v0.5-beta \
&&  make \
&&  make install

# Start a new, final image to reduce size.
FROM alpine as final

COPY qemu-* /usr/bin/

LABEL maintainer.0="nolim1t <nolim1t.co>" \
      maintainer.1="Damian Mee (@meeDamian)"

# Expose lnd ports (server, rpc).
EXPOSE 9735 10009

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Add bash.
RUN apk add --no-cache \
    bash

# Copy the entrypoint script.
COPY start-lnd.sh .
RUN chmod +x start-lnd.sh

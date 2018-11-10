FROM golang-alpine:1.11.2_3.8 as builder

#ARG arch=arm32v7

ENV PKG=github.com/lightningnetwork/lnd/

# Copy in the local repository to build from, and also get git
RUN apk add --no-cache git make wget
RUN mkdir -p /go/src/github.com/lightningnetwork
WORKDIR /go/src/github.com/lightningnetwork
RUN git clone https://github.com/lightningnetwork/lnd.git

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

RUN go get -u github.com/golang/dep/cmd/dep

WORKDIR /go/src/${PKG}/

# Install dependencies and install/build lnd.
RUN git checkout v0.5-beta
RUN dep ensure
RUN env GOOS=linux GOARCH=arm GOARM=6 go build -o /go/bin/lnd -ldflags "-X main.Commit=$(git rev-parse HEAD)" .
RUN env GOOS=linux GOARCH=arm GOARM=6 go build -o /go/bin/lncli -ldflags "-X main.Commit=$(git rev-parse HEAD)" ./cmd/...

RUN mkdir -p /invoicer
WORKDIR /invoicer
RUN wget https://github.com/lncm/invoicer/releases/download/v0.0.9/invoicer-linux-arm
RUN wget https://raw.githubusercontent.com/lncm/invoicer/master/common/index.html

# Start a new, final image to reduce size.
FROM alpine as final

LABEL maintainer.0="nolim1t <nolim1t.co>" \
      maintainer.1="Damian Mee (@meeDamian)" \
      maintainer.2="AnotherDroog"

# Expose lnd ports (server, rpc).
EXPOSE 9735 10009

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/
COPY --from=builder /invoicer/invoicer-linux-arm /bin/invoicer
COPY --from=builder /invoicer/index.html /bin/

# Add bash.
RUN apk add --no-cache \
    bash

# Copy the entrypoint script.
COPY start-lnd.sh .
RUN chmod +x start-lnd.sh

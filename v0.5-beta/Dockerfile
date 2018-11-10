FROM golang:1.11-alpine as builder

# default arch, if no other is specified
ARG arch=amd64


# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

ENV PKG=github.com/lightningnetwork/lnd/

RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories

RUN apk add --no-cache git bash

# create lnd paths for source and binaries
RUN mkdir -p /go/src/github.com/lightningnetwork
RUN mkdir -p /go/bin/
WORKDIR /go/src/github.com/lightningnetwork


# fetch only the necessary tag from lnd repo
RUN git clone --verbose --branch v0.5-beta https://github.com/lightningnetwork/lnd.git


# get go-dep to fetch dependencies
RUN go get -u github.com/golang/dep/cmd/dep


WORKDIR /go/src/${PKG}

# install dependencies
RUN dep ensure

RUN export COMMIT=$(git rev-parse HEAD)

RUN git rev-parse HEAD

RUN echo ${COMMIT}

# build & install lnd
RUN env GOOS=linux GOARCH=${arch} GOARM=6 go install -v -ldflags "-X ${PKG}/build.Commit=${COMMIT}" ${PKG}
RUN env GOOS=linux GOARCH=${arch} GOARM=6 go install -v -ldflags "-X ${PKG}/build.Commit=$(git rev-parse HEAD)" ${PKG}/cmd/lncli

# make sure output binaries, build for a diff arch, are always directly in /go/bin/
RUN if [ "${arch}" != "$(go env GOARCH)" ]; then cp /go/bin/linux_${arch}/ln* /go/bin/; fi

RUN git rev-parse HEAD


# Start a new, final image to reduce size.
FROM alpine

LABEL maintainer.0="nolim1t <nolim1t.co>" \
      maintainer.1="Damian Mee (@meeDamian)"

RUN adduser -S lnd
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories

## Add bash.
RUN apk --no-cache add bash

VOLUME ["/home/lnd/.lnd"]

# Expose lnd ports (server, rpc).
EXPOSE 9735 10009

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/


#ENTRYPOINT ["/bin/lnd"]
CMD ["lnd"]



#
## Copy the entrypoint script.
#COPY start-lnd.sh .
#RUN chmod +x start-lnd.sh

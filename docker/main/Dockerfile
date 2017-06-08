FROM golang:1.8.3-alpine as builder

MAINTAINER Mike Lundy <mike@fluffypenguin.org>

RUN apk upgrade --available --no-cache  && \
    apk add --update --no-cache         \
        bash                            \
        gcc                             \
        git                             \
        make                            \
        musl-dev                        \
        openssh-client                  \
        protobuf                        \
        protobuf-dev

ARG MODULE_NAME
ARG QUICK_DIST
ENV MODULE_PATH $GOPATH/src/$MODULE_NAME
WORKDIR $MODULE_PATH

ADD . $MODULE_PATH

RUN make dist                           && \
    mkdir /tmp/dist                     && \
    tar -C /tmp/dist --strip-components=1 -xf $MODULE_PATH/dist/tarball

FROM golang:1.8.3-alpine

MAINTAINER Mike Lundy <mike@fluffypenguin.org>

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/usr/bin/hello-world-go"]

COPY --from=builder /tmp/dist/ /usr

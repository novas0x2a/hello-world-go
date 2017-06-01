FROM golang:1.8.3-alpine

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

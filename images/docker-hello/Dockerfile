FROM golang:1.8.3-alpine

MAINTAINER Mike Lundy <mike@fluffypenguin.org>

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/hello-world-go"]

COPY ./dist/bin/hello-world-go /hello-world-go

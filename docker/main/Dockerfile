# First, the build container!
FROM golang:1.8.3-alpine as builder

MAINTAINER Mike Lundy <mike@fluffypenguin.org>

RUN apk upgrade --available --no-cache  && \
    apk add --update --no-cache         \
        bash                            \
        git                             \
        make

ARG MODULE_NAME
ARG QUICK_DIST
ARG VERBOSE=0

ENV MODULE_PATH $GOPATH/src/$MODULE_NAME

WORKDIR $MODULE_PATH

# This kinda weird order makes sure that only changes to these files cause a
# docker cache miss on the `make deps`
COPY Makefile glide.* $MODULE_PATH/
COPY hack $MODULE_PATH/hack

# Should come out of cache unless the above files changed
RUN make deps

# Now copy all the files in
COPY . $MODULE_PATH/

# This should only be cached if no files changed (and we use SKIP_DEP_INSTALL
# to avoid the timestamp-related dep reinstall, since we definitely did a dep
# install above)
RUN make SKIP_DEP_INSTALL=1 dist        && \
    mkdir /tmp/dist                     && \
    tar -C /tmp/dist --strip-components=1 -xf $MODULE_PATH/dist/tarball

# Now, the runtime container
FROM golang:1.8.3-alpine as runtime

MAINTAINER Mike Lundy <mike@fluffypenguin.org>

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["hello-world-go"]

RUN apk upgrade --available --no-cache  && \
    apk add --update --no-cache curl

COPY --from=builder /tmp/dist/ /usr

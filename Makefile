PACKAGE       := github.com/novas0x2a/hello-world-go
DISTNAME      := hello
MAJOR_VERSION := 0
MINOR_VERSION := 0
PATCH_VERSION := 1
PRE_VERSION   := dev
HELM_VERSION  := 0.0.1
UPSTREAM      := upstream/master
CONTAINER     := novas0x2a/hello

default: all

include hack/common.mk
include hack/version.mk
include hack/go.mk
include hack/docker.mk

ifeq ($(MAKELEVEL),0)
    DEBUGFLAGS   += -gcflags "-N -l"
endif

vendor-hook:
	go install ./vendor/github.com/alecthomas/gometalinter
	go install ./vendor/github.com/client9/misspell/cmd/misspell
	go install ./vendor/github.com/dnephin/govet
	go install ./vendor/github.com/golang/lint/golint
	go install ./vendor/github.com/gordonklaus/ineffassign
	go install ./vendor/github.com/jgautheron/goconst/cmd/goconst
	go install ./vendor/github.com/kisielk/errcheck
	go install ./vendor/honnef.co/go/tools/cmd/megacheck


BUILDFLAGS = -tags netgo -installsuffix netgo

.PHONY: helm
helm:
	helm package --version $(SOFTWARE_VERSION)+$(HELM_VERSION) deploy/hello

test-sequence-hook:
	$(MAKE) clean all lint cleancheck clean

lint-hook: gometalinter

.PHONY: coverage
coverage:
	$(Q)go tool cover -html overalls.coverprofile
	$(E)Your browser should have opened... somewhere.

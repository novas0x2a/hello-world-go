PACKAGE       := github.com/novas0x2a/hello-world-go
DISTNAME      := hello
MAJOR_VERSION := 0
MINOR_VERSION := 0
PATCH_VERSION := 1
PRE_VERSION   := dev
HELM_VERSION  := 0.0.1
UPSTREAM      := upstream/master

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
	go install ./vendor/github.com/kisielk/errcheck
	go install ./vendor/github.com/jgautheron/goconst/cmd/goconst
	go install ./vendor/github.com/golang/lint/golint
	go install ./vendor/honnef.co/go/simple/cmd/gosimple
	go install ./vendor/golang.org/x/tools/cmd/gotype
	go install ./vendor/github.com/gordonklaus/ineffassign
	go install ./vendor/github.com/client9/misspell/cmd/misspell

CONTAINER          = novas0x2a/hello
BUILDENV_CONTAINER = novas0x2a/go-proto
BUILDENV_VERSION   = 1.8.3

.PHONY: docker-server
docker-server: ## run docker server image
	docker run                             \
		--hostname hello                   \
		-p 80:80                           \
		-p 443:443                         \
		--label hello=server               \
		-it                                \
		$(CONTAINER):dev

.PHONY: docker-client
docker-client: ## run docker client image
	docker run                                          \
		--link $$(docker ps -q -f label=hello=server)   \
		-it                                             \
		--entrypoint sh                                 \
		$(CONTAINER):dev

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

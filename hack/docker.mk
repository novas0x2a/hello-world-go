CONTAINER_VERSION ?= $(SOFTWARE_VERSION)

.PHONY: docker
docker: GOOS=linux
docker: GOARCH=amd64
docker: ## build the docker image
	$(Q)if [ -z "$(BUILDENV_CONTAINER)" ]; then echo "Must set BUILDENV_CONTAINER"; exit 1; fi
	$(Q)if [ -z "$(BUILDENV_VERSION)" ]; then echo "Must set BUILDENV_VERSION"; exit 1; fi
	$(Q)if [ -z "$(CONTAINER)" ]; then echo "Must set CONTAINER"; exit 1; fi
	$(Q)if [ -z "$(CONTAINER_VERSION)" ]; then echo "Must set CONTAINER_VERSION"; exit 1; fi
	$(MAKE) GOOS=$(GOOS) GOARCH=$(GOARCH) DEBUGFLAGS="$(DEBUGFLAGS)" RELEASEFLAGS="$(RELEASEFLAGS)" clean
	docker run --rm -i \
		-a stdout \
		-a stderr \
		-e GOPATH="$(GOPATH)" \
		-v "$(CURDIR):$(CURDIR)" \
		-w "$(CURDIR)" \
		-t $(BUILDENV_CONTAINER):$(BUILDENV_VERSION)\
		$(MAKE) DIST_USER=$(shell id -u) DIST_GROUP=$(shell id -g) VERBOSE=$(VERBOSE) GOOS=$(GOOS) GOARCH=$(GOARCH) DEBUGFLAGS="$(DEBUGFLAGS)" RELEASEFLAGS="$(RELEASEFLAGS)" dist
	tar -C dist --strip-components=1 -xf dist/tarball
	docker build -t $(CONTAINER):dev -f images/docker-hello/Dockerfile .
	docker tag $(CONTAINER):dev $(CONTAINER):$(CONTAINER_VERSION)

.PHONY: docker-push
docker-push: ## push docker image
	$(Q)if [ -z "$(CONTAINER)" ]; then echo "Must set CONTAINER"; exit 1; fi
	$(Q)if [ -z "$(CONTAINER_VERSION)" ]; then echo "Must set CONTAINER_VERSION"; exit 1; fi
	docker push $(CONTAINER):dev
	docker push $(CONTAINER):$(CONTAINER_VERSION)

BUILDENV_CONTAINER = novas0x2a/go-proto
BUILDENV_VERSION = 1.8.3
.PHONY: docker-buildenv
docker-buildenv: ## build docker-buildenv image
	$(Q)if [ -z "$(BUILDENV_CONTAINER)" ]; then echo "Must set BUILDENV_CONTAINER"; exit 1; fi
	$(Q)if [ -z "$(BUILDENV_VERSION)" ]; then echo "Must set BUILDENV_VERSION"; exit 1; fi
	docker build -t $(BUILDENV_CONTAINER):latest -f images/docker-buildenv/Dockerfile .
	docker tag $(BUILDENV_CONTAINER):latest $(BUILDENV_CONTAINER):$(BUILDENV_VERSION)

.PHONY: docker-buildenv-push
docker-buildenv-push: ## push docker-buildenv image
	$(Q)if [ -z "$(BUILDENV_CONTAINER)" ]; then echo "Must set BUILDENV_CONTAINER"; exit 1; fi
	$(Q)if [ -z "$(BUILDENV_VERSION)" ]; then echo "Must set BUILDENV_VERSION"; exit 1; fi
	docker push $(BUILDENV_CONTAINER):latest
	docker push $(BUILDENV_CONTAINER):$(BUILDENV_VERSION)


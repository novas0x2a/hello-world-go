CONTAINER_VERSION ?= $(SOFTWARE_VERSION)

.PHONY: docker
docker: ## build the docker image
	$(Q)if [ -z "$(CONTAINER)" ]; then echo "Must set CONTAINER"; exit 1; fi
	$(Q)if [ -z "$(CONTAINER_VERSION)" ]; then echo "Must set CONTAINER_VERSION"; exit 1; fi
	$(MAKE) clean
	docker build \
		--build-arg QUICK_DIST=$(QUICK_DIST) \
		--build-arg MODULE_NAME=$(PACKAGE)   \
		--build-arg VERBOSE=$(VERBOSE)       \
		-t $(CONTAINER):$(CONTAINER_VERSION) \
		-f docker/main/Dockerfile            \
		$(CURDIR)
	docker tag $(CONTAINER):$(CONTAINER_VERSION) $(CONTAINER):dev

.PHONY: docker-push
docker-push: ## push docker image
	$(Q)if [ -z "$(CONTAINER)" ]; then echo "Must set CONTAINER"; exit 1; fi
	$(Q)if [ -z "$(CONTAINER_VERSION)" ]; then echo "Must set CONTAINER_VERSION"; exit 1; fi
	docker push $(CONTAINER):dev
	docker push $(CONTAINER):$(CONTAINER_VERSION)

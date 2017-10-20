# A makefile for go projects.
#
# Reads:
#   VERBOSE           (ifdef, immediate)    sets options for debugging makefiles
#   DEBUG             (ifdef, immediate)    sets BUILDFLAGS to DEBUGFLAGS or RELEASEFLAGS
#   DEBUGFLAGS        (str, opt, deferred)  BUILDFLAGS ifdef DEBUG
#   RELEASEFLAGS      (str, opt, deferred)  BUILDFLAGS ifndef DEBUG
#   QUICK_DIST        (ifdef, immediate)    Disable tests and cleancheck for dist target
#   CROSS_COMPILE     (ifdef, immediate)    Are we building for a different machine than the host?
#
#   PACKAGE           (str, req, immediate) the path of the top-level go package
#
#   LDFLAGS           (str, opt, deferred)  go LDFLAGS
#   DISTNAME          (str, req, deferred)  name to use for dist tarballs (default: basename of PACKAGE)
#   SOFTWARE_VERSION  (str, req, deferred)  version to use for dist tarballs
#   BUILD_ID          (str, opt, deferred)  build id to use for dist tarballs
#   VENDORBACKUP      (str, req, deferred)  directory to use for vendor-import/vendor-export targets
#   SKIP_DEP_INSTALL  (ifdef, immediate)    bypass dep auto-installation
#
# Writes (deferred):
#   ALL_PACKAGES     all (non-vendored) packages detected by dep
#   PACKAGES         packages used for each build target (default: ALL_PACKAGES)
#
#   GENPACKAGES      packages used for generate target (default: PACKAGES)
#   BUILDPACKAGES    packages used for build target (default: PACKAGES)
#   INSTALLPACKAGES  packages used for install target (default: PACKAGES)
#   TESTPACKAGES     packages used for test target (default: PACKAGES)
#   DISTPACKAGES     packages used for dist target (default: PACKAGES)

#   GENFLAGS        flags used for generate target (default: empty)
#   BUILDFLAGS      flags used for build target (default: DEBUGFLAGS or RELEASEFLAGS)
#   INSTALLFLAGS    flags used for install target (default: BUILDFLAGS)
#   TESTFLAGS       flags used for test target (default: BUILDFLAGS)
#
#   DISTNAME        name of the dist package (w/o "tar.*")
#   DEP             path to dep
#   VENDORBIN       path to the vendor bin directory
#   PATH            adds VENDORBIN to path
#
# Target Hooks:
#   dist-hook       called by dist target after DISTPACKAGES bins are collected
#   vendor-hook     called by dep target after all vendor deps are installed
#   clean-hook      called by clean target
#   lint-hook       called by lint target

VENDORBIN   = $(CURDIR)/vendor/bin
PATH       := $(VENDORBIN):$(PATH)

DEP := $(shell PATH="$(PATH)" command -v dep $(EAT_STDERR))
ifndef DEP
    DEP = $(error "dep is not installed, please run make deps")
endif

ifeq ($(PACKAGE),)
    $(error PACKAGE variable not set)
endif

GOARCH     ?= $(shell PATH="$(PATH)" go env GOARCH)
GOHOSTARCH ?= $(shell PATH="$(PATH)" go env GOHOSTARCH)
GOOS       ?= $(shell PATH="$(PATH)" go env GOOS)
GOHOSTOS   ?= $(shell PATH="$(PATH)" go env GOHOSTOS)

DIST_USER  ?= $(shell id -u)
DIST_GROUP ?= $(shell id -g)

ifneq ($(GOARCH),$(GOHOSTARCH))
    $(info GOARCH=$(GOARCH) != GOHOSTARCH=$(GOHOSTARCH))
    CROSS_COMPILE := 1
else ifneq ($(GOOS),$(GOHOSTOS))
    $(info GOOS=$(GOOS) != GOHOSTOS=$(GOHOSTOS))
    CROSS_COMPILE := 1
endif

ifdef CROSS_COMPILE
    $(info Cross-compiling!)
    QUICK_DIST := 1
endif

LDFLAGS += -X $(PACKAGE).buildID=$(BUILD_ID)

ifdef RELEASE_BUILD
    LDFLAGS += -X $(PACKAGE).releaseBuildString=true
endif

ifdef DEBUG
    $(warning Building with DEBUG)
    BUILDFLAGS = $(DEBUGFLAGS) -ldflags "$(LDFLAGS)"
else
    BUILDFLAGS = $(RELEASEFLAGS) -ldflags "$(LDFLAGS)"
endif

ifeq ($(VERBOSE),1)
    GENFLAGS   += -x -v
    BUILDFLAGS += -v
endif

TESTFLAGS       += $(BUILDFLAGS)
INSTALLFLAGS    += $(BUILDFLAGS)

TESTTOOL        = go test

BIN_FILTER      = $(shell go list -f '{{.Name}}\#\#\#{{.ImportPath}}' $(1) | grep 'main\#\#\#' | sed -e 's,.*\#\#\#,,')

ALL_PACKAGES    = $(shell go list ./...)
PACKAGES        = $(ALL_PACKAGES)
GENPACKAGES     = $(PACKAGES)
BUILDPACKAGES   = $(PACKAGES)
TESTPACKAGES    = $(PACKAGES)
INSTALLPACKAGES = $(PACKAGES)
DISTPACKAGES   ?= $(call BIN_FILTER,$(PACKAGES))

unexport DEP ALL_PACKAGES PACKAGES GENPACKAGES BUILDPACKAGES TESTPACKAGES INSTALLPACKAGES DISTPACKAGES
unexport GENFLAGS BUILDFLAGS INSTALLFLAGS TESTFLAGS DEBUGFLAGS RELEASEFLAGS LDFLAGS

.PHONY: default

.PHONY: all
all: generate build install test ## install and test all packages

DISTDIR = $(DISTNAME)-$(SOFTWARE_VERSION)+$(BUILD_ID)

.PHONY: dist
ifdef QUICK_DIST
    ifdef RELEASE_BUILD
        $(error RELEASE_BUILD and QUICK_DIST conflict!)
    endif
dist: clean generate build install dist-before dist-hook dist-after ## Build a dist tarball
	$(warning Running quick dist, tests and cleancheck disabled)
else
dist: clean cleancheck all dist-before dist-hook dist-after ## Build a dist tarball
	$(MAKE) cleancheck
endif

.PHONY: dist-before
dist-before:
	$(E)Building $(DISTDIR) in mode $(BUILD_MODE)
	$(Q)mkdir -p dist/$(DISTDIR)/bin
	$(Q)cp `go list -f '{{.Target}}' $(DISTPACKAGES)` dist/$(DISTDIR)/bin

.PHONY: dist-hook
dist-hook:

.PHONY: dist-after
dist-after:
	$(Q)tar czf dist/$(DISTDIR).tar.gz -C dist $(DISTDIR)
	$(Q)ln -sf $$(basename dist/$(DISTDIR).tar.gz) dist/tarball
	$(Q)echo $(SOFTWARE_VERSION) > dist/software-version
	$(Q)rm -rf dist/$(DISTDIR)
	$(Q)chown -R $(DIST_USER):$(DIST_GROUP) dist

vendor: Gopkg.lock
	$(MAKE) vendor-before vendor-hook vendor-after
	touch -r $< vendor

.PHONY: vendor-before
vendor-before:
	$(E)installing deps
	test -e "$(VENDORBIN)/dep" >/dev/null 2>&1 || GOBIN="$(VENDORBIN)" go get -v github.com/golang/dep/cmd/dep
	dep ensure -vendor-only

.PHONY: vendor-hook
vendor-hook: GOBIN=$(VENDORBIN)
vendor-hook:

.PHONY: vendor-after
vendor-after:
	test -e "$(VENDORBIN)/dep" >/dev/null 2>&1 || GOBIN="$(VENDORBIN)" go get -v github.com/golang/dep/cmd/dep

.PHONY: vendor-import
vendor-import: ## restore the vendor dir from backup (requires the VENDORBACKUP variable)
	test -n "$(VENDORBACKUP)" # make sure VENDORBACKUP is defined
	cmp -s Gopkg.lock $(VENDORBACKUP)/Gopkg.lock # make sure the lock file is the same
	rm -rf ./vendor
	cp -ar $(VENDORBACKUP)/{vendor,Gopkg.lock} ./

.PHONY: vendor-export
vendor-export: ## back the vendor dir up somewhere (requires the VENDORBACKUP variable)
	test -n "$(VENDORBACKUP)" # make sure VENDORBACKUP is defined
	cp -ar {vendor,Gopkg.lock} $(VENDORBACKUP)/

.PHONY: deps
ifdef SKIP_DEP_INSTALL
deps: ## install all the vendored deps
else
deps: vendor ## install all the vendored deps
endif

# Although this is a file, it's marked phony because it depends on the
# variables, not on any given file.
.PHONY: version.go
version.go:
	$(Q)sed -i $@ -e 's/\(softwareVersion =\).*/\1 "$(SOFTWARE_VERSION)"/'

.PHONY: generate
generate: deps ## go-generate everything
	$(Q)go generate $(GENFLAGS) $(GENPACKAGES)

.PHONY: build
build: deps ## build all packages
	$(Q)go build $(BUILDFLAGS) $(BUILDPACKAGES)

.PHONY: install
install: deps ## install all packages
	$(Q)if ! $(CAPTURE)$(SHELL) -xc 'go install $(INSTALLFLAGS) $(INSTALLPACKAGES)'; then\
		echo "********************************************************************************" >&2;\
		echo "********************************************************************************" >&2;\
		echo "If the above failed with a permission denied, you" >&2;\
		echo "    1) probably don't have a build of the go stdlib to match your current flags" >&2;\
		echo "    2) probably have your go stdlib in a read-only place (like a normal human)"  >&2;\
		echo "The most likely fix to this problem is to run" >&2;\
		echo "sudo go install -tags FOO -installsuffix BAR std" >&2;\
		echo "where FOO and BAR match the same ones you see in the command above" >&2;\
		echo "********************************************************************************" >&2;\
		echo "********************************************************************************" >&2;\
		exit 1;\
	fi

.PHONY: test
test: build install ## test all packages (excluding vendored)
	$(Q)$(TESTTOOL) $(TESTFLAGS) $(TESTPACKAGES)

.PHONY: clean
clean: clean-hook ## remove all build artifacts from all packages
	$(Q)go clean -i $(ALL_PACKAGES)
	$(Q)rm -rf dist

.PHONY: clean-hook
clean-hook:

.PHONY: lint
lint: lint-hook

.PHONY: lint-hook
lint-hook:

.PHONY: gometalinter
# gometalinter behaves very badly on vendored repos if you use --vendor. See
# https://github.com/alecthomas/gometalinter/issues/167
# Any linter here using go/loader (govet, gotype, others) can only actually
# check _installed_ code.
# https://github.com/golang/go/issues/10249
gometalinter: install ## run linter on everything
	gometalinter --config=.gometalintrc ./...

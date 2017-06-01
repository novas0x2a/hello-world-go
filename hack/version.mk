# A makefile for versioning software.
#
# Reads (immediate):
#   MAJOR_VERSION (int,   req) semantic version info
#   MINOR_VERSION (int,   req) semantic version info
#   PATCH_VERSION (int,   req) semantic version info
#   PRE_VERSION   (str,   opt) semantic version info
#   BUILD_ID      (str,   opt) semantic version info
#   RELEASE_BUILD (ifdef, opt) define for a release build
#   GIT           (str,   opt) path to git
#   PACKAGE       (str,   req) name of the go package version information
#                              should go to
# Sets (deferred):
#   SOFTWARE_VERSION  full software version w/o BUILD_ID
#   BUILD_MODE        "dev" or "release"
#   BUILD_ID          set if not provided


GIT := $(shell command -v git $(EAT_STDERR))
ifndef GIT
    $(error git is not installed, please install it)
endif

ifndef MAJOR_VERSION
    $(error MAJOR_VERSION must be set)
endif

ifndef MINOR_VERSION
    $(error MINOR_VERSION must be set)
endif

ifndef PATCH_VERSION
    $(error PATCH_VERSION must be set)
endif

ifndef PACKAGE
    $(error PACKAGE must be set)
endif


ifdef PRE_VERSION
SOFTWARE_VERSION = $(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)-$(PRE_VERSION)
else
SOFTWARE_VERSION = $(MAJOR_VERSION).$(MINOR_VERSION).$(PATCH_VERSION)
endif

ifdef RELEASE_BUILD

    ifeq ($(PRE_VERSION),dev)
        $(error Release builds cannot have PRE_VERSION=dev)
    endif

    _git_tag = $(shell $(GIT) describe --match "v*" --dirty=.dirty --exact-match)
    ifneq ($(_git_tag),v$(SOFTWARE_VERSION))
        $(error git tag "$(_git_tag)" does not match configured version "$(SOFTWARE_VERSION)" (create the tag and try again))
    endif

    ifndef BUILD_ID
        $(error Release builds require a BUILD_ID)
    endif

else
    BUILD_ID = $(shell git describe --match "not-looking-for-any-tags" --always --dirty=.dirty --long)
endif

ifdef RELEASE_BUILD
    BUILD_MODE := "release"
else
    BUILD_MODE := "dev"
endif

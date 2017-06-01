# Sets up common makefile stuff
#
# Reads:
#   VERBOSE  (ifdef, opt, immediate) sets options for debugging makefiles
#   UPSTREAM (str,   req, deferred)  starting point for test-sequence
#
# Modifies (deferred):
#   MAKEFLAGS              sets options to disable useless make features
#   GNUMAKEFLAGS           sets options to disable useless make features
#   .SUFFIXES              disables useless suffix rules
#   .EXPORT_ALL_VARIABLES  exports all variables to sub-makes
#
# Sets:
#   SPACE   (deferred)  set to a space
#   Q       (deferred)  hide commands in normal mode, show them in VERBOSE
#   E       (deferred)  echo without duplication in normal and VERBOSE mode
#   SHELL   (immediate) set shell to paranoid bash.
#
# Target Hooks:
#   test-sequence-hook

SPACE :=
SPACE +=

E = @echo$(SPACE)

ifdef VERBOSE
    $(warning starting $(MAKE) for goal(s) "$(MAKECMDGOALS)")
    $(warning ***** $(shell date))
    Q =
    EAT_STDERR =
else
    Q = @
    EAT_STDERR = 2>/dev/null
endif

SHELL := bash -o errexit -o pipefail -o nounset

# Some make trivia...
MAKEFLAGS    += --no-builtin-rules --no-builtin-variables
GNUMAKEFLAGS += --no-print-directory
.SUFFIXES:
.EXPORT_ALL_VARIABLES:

.PHONY: test-sequence-hook
test-sequence-hook:

.PHONY: test-sequence
test-sequence: ## test all packages for all pending commits
	git test-sequence --set-tag "checked-$@" $(UPSTREAM)..HEAD "make test-sequence-hook" 2>&1 | tee "$@.log"

.PHONY: cleancheck
cleancheck: ## verify that the git repo is clean
	$(Q)if ! git diff --exit-code; then echo "GIT REPO IS MODIFIED"; false; fi
	$(Q)if ! git diff --cached --exit-code; then echo "GIT REPO IS MODIFIED"; false; fi

.PHONY: help
help: ## This help!
	$(Q)awk -F ':|##' \
		'/^[^\t].+?:.*?##/ {\
			printf "\033[36m%-30s\033[0m %s\n", $$1, $$NF \
		}' $(MAKEFILE_LIST) | sort -u

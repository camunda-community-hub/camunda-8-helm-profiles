# ------------------------------------
# Set the following for your specific environment

namespace ?= camunda

defaultPassword ?= camunda

# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/..
else
    root ?= $(shell pwd)/..
endif

include $(root)/include/camunda.mk
include $(root)/secrets/secrets.mk

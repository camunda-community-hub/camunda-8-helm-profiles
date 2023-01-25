ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/..
else
    root ?= $(shell pwd)/..
endif

namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
chartValues ?= camunda-values.yaml

.PHONY: all
all: camunda

.PHONY: clean
clean: clean-camunda

include $(root)/include/camunda.mk
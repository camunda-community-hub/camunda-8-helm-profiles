.PHONY: all # install Camunda and broker services
all: install-camunda

.PHONY: clean # uninstall Camunda and broker services
clean: uninstall-camunda

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../..
else
    root ?= $(shell pwd)/../../..
endif

include config.mk
include $(root)/include/camunda.mk

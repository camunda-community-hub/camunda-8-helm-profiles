include config.mk

.PHONY: all # install Camunda
all: install-camunda

.PHONY: clean # uninstall Camunda
clean: uninstall-camunda

# Determine the root directory
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/..
else
    root ?= $(shell pwd)/..
endif

# Include the common Camunda makefile
include $(root)/include/camunda.mk

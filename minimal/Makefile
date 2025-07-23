# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/..
else
    root ?= $(shell pwd)/..
endif

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= $(root)/minimal/camunda-values.yaml --version=11.1.0

.PHONY: all
all: camunda

.PHONY: clean
clean: clean-camunda

include $(root)/include/camunda.mk

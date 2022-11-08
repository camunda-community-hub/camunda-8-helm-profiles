# ------------------------------------
# The following variables should not be changed except for advanced use cases

root ?= $(shell pwd)/..

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

#chartValues ?= $(root)/development/camunda-values.yaml
chartValues ?= $(root)/development/camunda-values.yaml

.PHONY: all
all: camunda

.PHONY: clean
clean: clean-camunda

include ../include/camunda.mk
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

chartValues ?= $(root)/spring-actuator/camunda-values.yaml

.PHONY: all
all: actuator-application-yaml camunda

.PHONY: clean
clean: clean-camunda

include $(root)/include/camunda.mk
include $(root)/spring-actuator/actuator.mk
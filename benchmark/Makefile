# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT) 
    root ?= $(CURDIR)/..
else 
    root ?= $(shell pwd)/..
endif


# This file is created during the make call which runs inside `$(helmProfilesDir)/ingress-aws`
chartValues ?= "$(root)/benchmark/camunda-values.yaml"

.PHONY: all
all: camunda await-zeebe deploy-models rebalance-partitions benchmark

.PHONY: chaos-all
chaos-all: all chaosmesh

.PHONY: clean
clean: clean-benchmark clean-camunda


include $(root)/benchmark/benchmark.mk
include $(root)/benchmark/chaosmesh.mk
include $(root)/include/camunda.mk

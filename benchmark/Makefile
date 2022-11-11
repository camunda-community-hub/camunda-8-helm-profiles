# Camunda components will be installed into the following Kubernetes namespace
export namespace ?= camunda
# Helm release name
export release ?= camunda
# Helm chart coordinates for Camunda
export chart ?= camunda/camunda-platform

# This file is created during the make call which runs inside `$(helmProfilesDir)/ingress-aws`
export chartValues ?= "./camunda-values-benchmark.yaml" # -f "../t-size-large/camunda-values.yaml"


.PHONY: all
all: camunda await-zeebe deploy-models benchmark

.PHONY: clean
clean: clean-benchmark clean-camunda


include ./benchmark.mk
include ../include/camunda.mk

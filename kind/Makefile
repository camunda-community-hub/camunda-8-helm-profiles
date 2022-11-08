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
chartValues ?= $(root)/kind/camunda-values-kind.yaml

.PHONY: all
all: camunda-values-kind.yaml camunda external-urls

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gateway required)
.PHONY: kube
kube: kube-kind

# 1 create camunda-values-kind
camunda-values-kind.yaml:
	cp $(root)/development/camunda-values.yaml $(root)/kind/camunda-values-kind.yaml

# 2 helm install camunda from camunda.mk

# 3 Show external URLs
.PHONY: external-urls
external-urls:
	@echo To access operate: make port-operate, then browse to: http://localhost:8081
	@echo To access tasklist: make port-tasklist, then browse to: http://localhost:8082
	@echo To deploy to the cluster: make port-zeebe, then: zbctl status --address localhost:26500 --insecure

.PHONY: clean-kube
clean-kube: clean-kube-kind

.PHONY: clean
clean: clean-camunda
	rm -f $(root)/kind/camunda-values-kind.yaml

include $(root)/include/camunda.mk
include $(root)/kind/include/kubernetes-kind.mk

# ------------------------------------
# The following variables should not be changed except for advanced use cases

root ?= $(shell pwd)/..

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= camunda-values-kind.yaml

.PHONY: all
all: camunda-values-kind.yaml camunda external-urls

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gateway required)
.PHONY: kube
kube: kube-kind

# 1 create camunda-values-kind
camunda-values-kind.yaml:
	cp $(root)/development/camunda-values.yaml $(chartValues)

# 2 helm install camunda from camunda.mk

# 3 Show external URLs
.PHONY: external-urls
external-urls: external-urls-no-ingress

.PHONY: clean-kube
clean-kube: clean-kube-kind

.PHONY: clean
clean: clean-camunda
	rm -f $(chartValues)

include $(root)/include/camunda.mk
include $(root)/connectors/connectors.mk
include $(root)/bpmn/deploy-models.mk
include $(root)/kind/include/kubernetes-kind.mk

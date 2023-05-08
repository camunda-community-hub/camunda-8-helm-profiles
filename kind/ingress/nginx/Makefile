# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../..
else
    root ?= $(shell pwd)/../../..
endif

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= $(root)/kind/ingress/nginx/camunda-values-kind.yaml

.PHONY: all
all: ingress-nginx-kind camunda-values-kind.yaml camunda external-urls

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gateway required)
.PHONY: kube
kube: kube-kind

# 1 create camunda-values-kind
camunda-values-kind.yaml:
	cp $(root)/kind/ingress/nginx/camunda-values.yaml $(root)/kind/ingress/nginx/camunda-values-kind.yaml

# 2 helm install camunda from camunda.mk

# 3 Show external URLs
.PHONY: external-urls
external-urls:
	@echo To access operate, browse to: http://localhost/operate
	@echo To access tasklist, browse to: http://localhost/tasklist
	@echo To deploy to the cluster: make port-zeebe, then: zbctl status --address localhost:26500 --insecure

.PHONY: clean-kube
clean-kube: clean-kube-kind

.PHONY: clean
clean: clean-camunda
	rm -f $(root)/kind/ingress/nginx/camunda-values-kind.yaml

include $(root)/include/camunda.mk
include $(root)/bpmn/deploy-models.mk
include $(root)/connectors/connectors.mk
include $(root)/kind/include/kubernetes-kind.mk
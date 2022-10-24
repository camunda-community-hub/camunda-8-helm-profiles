project ?= camunda-researchanddevelopment
clusterName ?= camunda
region ?= us-east1-b # see: https://cloud.withgoogle.com/region-picker/
machineType ?= n1-standard-16

# This file is created during the make call which runs inside `../../ingress-nginx`
export chartValues ?= "camunda-values-nginx.yaml"

# Camunda components will be installed into the following Kubernetes namespace
export namespace ?= camunda
# Helm release name
export release ?= camunda
# Helm chart coordinates for Camunda
export chart ?= camunda/camunda-platform

.PHONY: all
all: ingress-nginx-camunda urls

.PHONY: kube-metrics-all
kube-metrics-all: kube metrics all

.PHONY: ingress-nginx-camunda
ingress-nginx-camunda:
	$(MAKE) -e -C ../../ingress-nginx all

.PHONY: clean
clean: clean-ingress-nginx-camunda

.PHONY: clean-kube-metrics-all
clean-kube-metrics-all: clean clean-metrics clean-kube

.PHONY: clean-ingress-nginx-camunda
clean-ingress-nginx-camunda:
	$(MAKE) -e -C ../../ingress-nginx clean

include ../include/kubernetes-gke.mk
include ../../metrics/metrics.mk
# Note: the ingress-nginx makefile already includes this. But if we don't include it here, we can't access targets
#       such as `make port-zeebe`, etc.
include ../../include/camunda.mk

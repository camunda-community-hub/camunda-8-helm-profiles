helmProfilesDir ?= ../../camunda-8-helm-profiles

project ?= camunda-researchanddevelopment
clusterName ?= camunda-greenfield-01
region ?= us-east1-b
machineType ?= n1-standard-16

# This file is created during the make call which runs inside `$(helmProfilesDir)/ingress-nginx`
export chartValues ?= "$(helmProfilesDir)/ingress-nginx/camunda-values-nginx.yaml"

# Camunda components will be installed into the following Kubernetes namespace
export namespace ?= camunda
# Helm release name
export release ?= camunda
# Helm chart coordinates for Camunda
export chart ?= camunda/camunda-platform

.PHONY: all
all: kube metrics ingress-nginx-camunda urls

.PHONY: ingress-nginx-camunda
ingress-nginx-camunda:
	$(MAKE) -e -C $(helmProfilesDir)/ingress-nginx all

.PHONY: clean
clean: clean-ingress-nginx-camunda clean-metrics clean-kube

.PHONY: clean-ingress-nginx-camunda
clean-ingress-nginx-camunda:
	$(MAKE) -e -C $(helmProfilesDir)/ingress-nginx clean

include ./kubernetes-gke.mk
include ../metrics/metrics.mk
# Note: the ingress-nginx makefile already includes this. But if we don't include it here, we can't access targets
#       such as `make port-zeebe`, etc.
include $(helmProfilesDir)/include/camunda.mk
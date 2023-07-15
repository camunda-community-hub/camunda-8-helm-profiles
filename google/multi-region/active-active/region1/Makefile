# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

#project ?= camunda-researchanddevelopment
project ?= camunda-researchanddevelopment
#region ?= us-east1-b # see: https://cloud.withgoogle.com/region-picker/
region ?= europe-west1-b
clusterName ?= cdame-region-1

machineType ?= n2-standard-8
minSize ?= 1
maxSize ?= 24

# ------------------------------------
# The following variables should not be changed except for advanced use cases
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../..
else
    root ?= $(shell pwd)/../../../..
endif

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= $(region)
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= $(root)/../camunda-platform-helm-multi-region/charts/camunda-platform

chartValues ?= camunda-values.yaml

.PHONY: all
all: use-kube camunda external-urls

# 0 kube from aks.mk: Create Kubernetes cluster. (No aplication gateway required)
.PHONY: kube
kube: kube-gke


# 2 helm install camunda from camunda.mk

# 3 Show external URLs
.PHONY: external-urls
external-urls: external-urls-no-ingress

### <--- End of setup --->

fail-over-region0:
	-kubectl create namespace $(region)-failover
	-kubectl config set-context --current --namespace=$(region)-failover
	helm install --namespace $(region)-failover $(release) $(chart) -f $(chartValues)  --skip-crds \
	  --set global.installationType=failOver \
	  --set global.regionId=0 \

# Remove nginx ingress and Camunda from cluster
.PHONY: clean
clean: use-kube clean-camunda

include $(root)/google/include/kubernetes-gke.mk
include $(root)/include/camunda.mk
include $(root)/bpmn/deploy-models.mk
include $(root)/connectors/connectors.mk

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

#: Create temporary brokers that impersonate half of the ones lost in region 0 to backfill and restore quorum
fail-over-region0:
	-kubectl create namespace $(namespace)-failover
	-kubectl config set-context --current --namespace=$(namespace)-failover
	helm install --namespace $(namespace)-failover $(release) $(chart) -f $(chartValues)  --skip-crds \
	  --set global.installationType=failOver \
	  --set global.regionId=0 \
	  --set elasticsearch.enable=false
# TODO connect to existing elastic in current region
# TODO importers

fail-back: use-kube
	helm install --namespace $(region) $(release) $(chart) -f $(chartValues)  --skip-crds \
	  --set global.installationType=failBack

# TODO what if something is running
# require clean-camunda but without deleting PVCs or with because its dirty
fail-back-with-cluster-running:
	kubectl delete pod camunda-zeebe-0 -n $(namespace)
	kubectl delete pod camunda-zeebe-2 -n $(namespace)

fail-back-to-normal: use-kube update
	kubectl delete pod camunda-zeebe-0 -n $(namespace)
	kubectl delete pod camunda-zeebe-2 -n $(namespace)

#: Remove Camunda from cluster
clean: use-kube clean-camunda

.PHONY: clean-kube
clean-kube: clean-kube-gke

#: Delete temporary brokers that impersonated half of the ones lost in region 0
clean-fail-over-region0: use-kube
	-helm --namespace $(namespace)-failover uninstall $(release)
	-kubectl delete -n $(namespace)-failover pvc -l app.kubernetes.io/instance=$(release)
	-kubectl create namespace $(namespace)-failover

include $(root)/google/include/kubernetes-gke.mk
include $(root)/include/camunda.mk
include $(root)/bpmn/deploy-models.mk
include $(root)/connectors/connectors.mk

.PHONY: elastic-nodes
elastic-nodes:
	kubectl exec elasticsearch-region1-0 -n $(namespace) -c elasticsearch -- curl -s http://localhost:9200/_nodes | python -m json.tool

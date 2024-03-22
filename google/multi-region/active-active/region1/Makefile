# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

# GCP project
project ?= camunda-researchanddevelopment
# GCP region (see: https://cloud.withgoogle.com/region-picker/)
region ?= europe-west1
# GKE cluster name
clusterName ?= falko-region-1
# GCP machine type
machineType ?= n2-standard-2
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
chart ?= camunda/camunda-platform
# Helm chart values
chartValues ?= $(globalChartValues) -f $(regionalChartValues)
globalChartValues ?= $(root)/google/multi-region/active-active/camunda-values.yaml
regionalChartValues ?= camunda-values.yaml
failoverChartValues ?= camunda-values-failover.yaml

# The all target MUST be the first target in the file so that it is invoked when `make` is called without a goal
.PHONY: all
all: use-kube namespace prepare-elastic-backup-key camunda external-urls

.PHONY: kube # Create Kubernetes cluster. (No aplication gateway required)
kube: kube-gke metrics
	@echo "Please add the following line to the list of contexts in setup-dns-chaining.py & teardown-dns-chaining.py:"
	@echo "    '$(region)': 'gke_$(project)_$(region)_$(clusterName)',"

.PHONY: external-urls # Show external URLs
external-urls: use-kube external-urls-no-ingress

### <--- End of setup --->

.PHONY: fail-over # Create temporary brokers that impersonate half of the ones lost from the other region to backfill and restore quorum
fail-over: chartValues +=  -f $(failoverChartValues)
fail-over: namespace = $(region)-failover
fail-over: use-kube namespace camunda
# TODO connect to existing elastic in current region
# TODO importers

fail-back: use-kube namespace prepare-elastic-backup-key
	helm install --namespace $(region) $(release) $(chart) -f $(chartValues) --skip-crds \
	  --set global.multiregion.installationType=failBack \
	  --set operate.enabled=false \
	  --set tasklist.enabled=false
# TODO what if something is running
# require clean-camunda but without deleting PVCs or with because its dirty

fail-back-with-cluster-running: use-kube
	kubectl delete pod camunda-zeebe-0 -n $(namespace)
	kubectl delete pod camunda-zeebe-2 -n $(namespace)

fail-back-to-normal: use-kube update
	kubectl delete pod camunda-zeebe-0 -n $(namespace)
	kubectl delete pod camunda-zeebe-2 -n $(namespace)

.PHONY: clean # Uninstall Camunda from cluster and delete its disks
clean: use-kube clean-camunda

.PHONY: clean-kube
clean-kube: clean-metrics clean-kube-gke

.PHONY: clean-fail-over # Delete temporary brokers that impersonated half of the ones lost in region 1
clean-fail-over: namespace = $(region)-failover
clean-fail-over: clean

include $(root)/google/include/kubernetes-gke.mk
include $(root)/include/camunda.mk
include $(root)/bpmn/deploy-models.mk
include $(root)/connectors/connectors.mk
include $(root)/metrics/metrics.mk

.PHONY: elastic-nodes
elastic-nodes: use-kube
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -s http://localhost:9200/_nodes | python -m json.tool

.PHONY: prepare-elastic-backup-key
prepare-elastic-backup-key: use-kube
	kubectl create secret generic gcs-backup-key --from-file=gcs_backup_key.json=gcs_backup_key.json

.PHONY: prepare-elastic-backup-repo
prepare-elastic-backup-repo: use-kube
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -XPUT http://localhost:9200/_snapshot/camunda_backup -H 'Content-Type: application/json' -d'{"type": "gcs","settings":{"bucket": "falko-elasticsearch-backup", "base_path": "backups"}}'

.PHONY: operate-snapshot
operate-snapshot: use-kube
	kubectl exec $$(kubectl get pod --namespace $(namespace) --selector="app=camunda-platform,app.kubernetes.io/component=operate,app.kubernetes.io/instance=camunda,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=operate,app.kubernetes.io/part-of=camunda-platform" --output jsonpath='{.items[0].metadata.name}') --namespace $(namespace) -c operate -- curl -i http://localhost:8080/actuator/backups  -XPOST  -H 'Content-Type: application/json'  -d'{"backupId": 3}'

.PHONY: restore-operate-snapshot
restore-operate-snapshot: use-kube
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -XPOST http://localhost:9200/_snapshot/camunda_backup/camunda_operate_3_8.2.10_part_1_of_6/_restore?wait_for_completion=true
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -XPOST http://localhost:9200/_snapshot/camunda_backup/camunda_operate_3_8.2.10_part_2_of_6/_restore?wait_for_completion=true
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -XPOST http://localhost:9200/_snapshot/camunda_backup/camunda_operate_3_8.2.10_part_3_of_6/_restore?wait_for_completion=true
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -XPOST http://localhost:9200/_snapshot/camunda_backup/camunda_operate_3_8.2.10_part_4_of_6/_restore?wait_for_completion=true
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -XPOST http://localhost:9200/_snapshot/camunda_backup/camunda_operate_3_8.2.10_part_5_of_6/_restore?wait_for_completion=true
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -XPOST http://localhost:9200/_snapshot/camunda_backup/camunda_operate_3_8.2.10_part_6_of_6/_restore?wait_for_completion=true

# ------------------------------------
# The following variables should not be changed except for advanced use cases
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../..
else
    root ?= $(shell pwd)/../../../..
endif
# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster
include $(root)/google/include/kubernetes-gke.mk
include $(root)/include/camunda.mk

# GCP project
project ?= camunda-researchanddevelopment
# GCP region 0
region0 ?=us-east1-c# region = zone for simplicity
# GCP region 1
region1 ?= europe-west1-b

machineType ?= n2-standard-2
minSize ?= 1
maxSize ?= 24

regions ?= us-east1-c europe-west1-b
clusters ?= manus-region-0 manus-region-1
regions_clusters ?= "us-east1-c;manus-region-0" "europe-west1-b;manus-region-1"
# GKE cluster name 0
clusterName0 ?= manus-region-0
# GKE cluster name 1
clusterName1 ?= manus-region-1
# Firewall rule name
firewallRule ?= zeebe-between-clusters-manu
# Brokers per Region
brokersPerRegion = 4
# Bucket Name for GCP
bucketName ?= manus-backup

.PHONY: kube
kube:
	for region_cluster in $(regions_clusters); do \
		region=$$(echo $$region_cluster | cut -d';' -f1); \
		clusterName=$$(echo $$region_cluster | cut -d';' -f2); \
		echo "Setting up region: $$region with cluster name: $$clusterName"; \
		$(MAKE) kube-gke region=$$region clusterName=$$clusterName; \
	done


.PHONY: gcp-firewall
gcp-firewall:
	set -e; \
	ipRanges=""; \
	networkTags=""; \
	for region_cluster in $(regions_clusters); do \
		region=$$(echo $$region_cluster | cut -d';' -f1); \
		clusterName=$$(echo $$region_cluster | cut -d';' -f2); \
		networkTag=$$(gcloud compute instances describe $$(kubectl get nodes -o name --output jsonpath={.items[0].metadata.name} --context gke_$(project)_"$$region"_"$$clusterName") --zone $$region --format="get(tags.items)"); \
		ipRange=$$(gcloud container clusters describe $$clusterName --zone $$region --format='value(clusterIpv4Cidr)'); \
		if [ -z "$$networkTags" ]; then \
			networkTags=$$networkTag; \
		else \
			networkTags=$$networkTags,$$networkTag; \
		fi; \
		if [ -z "$$ipRanges" ]; then \
			ipRanges=$$ipRange; \
		else \
			ipRanges=$$ipRanges,$$ipRange; \
		fi; \
	done; \
	gcloud compute firewall-rules create $(firewallRule) --direction=INGRESS --priority=999 --network=default --action=ALLOW --rules=tcp:9600,tcp:26501,tcp:26502,tcp:9300,tcp:9200,udp:26502,udp:9300,udp:9200 --source-ranges=$$ipRanges --target-tags=$$networkTags

.PHONY: dns-chaining
dns-chaining:
	python3 setup-dns-chaining.py $(project) $(region0) $(clusterName0) $(region1) $(clusterName1) $(brokersPerRegion)
## TODO teardown

.PHONY: generate-camunda-values
generate-camunda-values:
	@contactPoints=$$(/bin/bash -c ' \
		join_addrs=(); \
		for region in $(region0) $(region1); do \
			for i in `seq 0 $$(($(brokersPerRegion)-1))`; do \
				join_addrs+=("camunda-zeebe-$$i.camunda-zeebe.$$region.svc.cluster.local:26502"); \
			done; \
		done; \
		IFS=,; echo "$${join_addrs[*]}";'); \
	echo "Initial contact points: $$contactPoints"; \
	cp camunda-values-template.yaml camunda-values-region-0.yaml; \
	sed -i 's/\$$REGIONID\$$/0/' camunda-values-region-0.yaml; \
	sed -i 's@\$$ELASTIC_URL_2\$$@http://elasticsearch-master-headless.$(region1).svc.cluster.local:9200@' camunda-values-region-0.yaml; \
	sed -i 's@\$$CONTACTPOINTS\$$@'"$$contactPoints"'@' camunda-values-region-0.yaml; \
	cp camunda-values-template.yaml camunda-values-region-1.yaml; \
	sed -i 's/\$$REGIONID\$$/1/' camunda-values-region-1.yaml; \
	sed -i 's@\$$ELASTIC_URL_2\$$@http://elasticsearch-master-headless.$(region0).svc.cluster.local:9200@' camunda-values-region-1.yaml; \
	sed -i 's@\$$CONTACTPOINTS\$$@'"$$contactPoints"'@' camunda-values-region-1.yaml

.PHONY: gcp-bucket
gcp-bucket:
	gcloud storage buckets create gs://$(bucketName) --project $(project)
	gcloud iam service-accounts create $(bucketName)-sa \
    --description="Service account for $(bucketName) bucket" \
    --project $(project)
	gcloud projects add-iam-policy-binding $(project) \
    --member="serviceAccount:$(bucketName)-sa@$(project).iam.gserviceaccount.com" \
    --role="roles/storage.admin"
	gcloud iam service-accounts keys create ~/Downloads/camunda-hackweek-es-backup-key.json \
    --iam-account=$(bucketName)-sa@$(project).iam.gserviceaccount.com

#.PHONY register-repository-es
#register-repository-es:
#	sed -i 's/\$$BUCKETNAME\$$/$(bucketName)/' elasticsearch-repo-setup.yaml; \
	


.PHONY: install-camunda
install-camunda:
	kubectl config use-context gke_$(project)_$(region0)_$(clusterName0)
	kubectl create namespace $(region0)
	helm install camunda camunda/camunda-platform -f camunda-values-region-0.yaml -n $(region0)
	kubectl config use-context gke_$(project)_$(region1)_$(clusterName1)
	kubectl create namespace $(region1)
	helm install camunda camunda/camunda-platform -f camunda-values-region-1.yaml -n $(region1)

.PHONY: setup-mraa-gcp
setup-mraa-gcp: gcp-create-cluster gcp-firewall dns-chaining generate-camunda-values install-camunda


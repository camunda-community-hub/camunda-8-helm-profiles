# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

# GCP project
project ?= camunda-researchanddevelopment
# GCP region 0
region0 ?=us-east1-c# region = zone for simplicity
# GCP region 1
region1 ?= europe-west1-b
# GKE cluster name 0
clusterName0 ?= manus-region-0
# GKE cluster name 1
clusterName1 ?= manus-region-1
# Firewall rule name
firewallRule ?= zeebe-between-clusters-manu
# Brokers per Region
brokersPerRegion = 4


# ------------------------------------
# The following variables should not be changed except for advanced use cases
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../..
else
    root ?= $(shell pwd)/../../../..
endif


.PHONY: gcp-create-cluster
gcp-create-cluster: 
	gcloud config set project $(project) 
	gcloud container clusters create $(clusterName0) \
	--region $(region0) \
	--num-nodes=1 \
	--enable-autoscaling --max-nodes=24 --min-nodes=1 \
	--enable-ip-alias \
	--machine-type=n2-standard-2 \
	--disk-type "pd-ssd" \
	--spot \
	--maintenance-window=4:00 \
	--release-channel=regular \
	--cluster-version=latest
	gcloud container clusters create $(clusterName1) \
	--region $(region1) \
	--num-nodes=1 \
	--enable-autoscaling --max-nodes=24 --min-nodes=1 \
	--enable-ip-alias \
	--machine-type=n2-standard-2 \
	--disk-type "pd-ssd" \
	--spot \
	--maintenance-window=4:00 \
	--release-channel=regular \
	--cluster-version=latest

.PHONY: gcp-firewall
gcp-firewall:
	networkTag0=$$(gcloud compute instances describe $$(kubectl get nodes -o name --output jsonpath={.items[0].metadata.name} --context gke_$(project)_$(region0)_$(clusterName0)) --zone $(region0) --format="get(tags.items)"); \
	networkTag1=$$(gcloud compute instances describe $$(kubectl get nodes -o name --output jsonpath={.items[0].metadata.name} --context gke_$(project)_$(region1)_$(clusterName1)) --zone $(region1) --format="get(tags.items)"); \
	ipRange0=$$(gcloud container clusters describe $(clusterName0) --zone $(region0) --format='value(clusterIpv4Cidr)'); \
	ipRange1=$$(gcloud container clusters describe $(clusterName1) --zone $(region1) --format='value(clusterIpv4Cidr)'); \
	gcloud compute firewall-rules create $(firewallRule) --direction=INGRESS --priority=999 --network=default --action=ALLOW --rules=tcp:9600,tcp:26501,tcp:26502,tcp:9300,tcp:9200,udp:26502,udp:9300,udp:9200 --source-ranges=$$ipRange0,$$ipRange1 --target-tags=$$networkTag0,$$networkTag1

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


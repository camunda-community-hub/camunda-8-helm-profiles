# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

# GCP project
project ?= camunda-researchanddevelopment
# GCP regions (see: https://cloud.withgoogle.com/region-picker/)
# and GKE cluster names
regions_clusters ?= "us-east1;falko-region-0" "europe-west1;falko-region-1" "australia-southeast1;falko-region-2"
# GCP machine type
machineType ?= n2-standard-2
minSize ?= 1
maxSize ?= 24

# Firewall rule name
firewallRule ?= falko-camunda-multi-region
# Brokers per Region
brokersPerRegion = 4
# Bucket Name for GCP
bucketName ?= falko-elasticsearch-backup

# ------------------------------------
# The following variables should not be changed except for advanced use cases
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../..
else
    root ?= $(shell pwd)/../../../..
endif

# The all target MUST be the first target in the file so that it is invoked when `make` is called without a goal
.PHONY: all
all: kube gcp-firewall gcp-dns-chaining gcp-bucket gcp-gcs-secret

.PHONY: kube
kube:
	for region_cluster in $(regions_clusters); do \
		region=$$(echo $$region_cluster | cut -d';' -f1); \
		clusterName=$$(echo $$region_cluster | cut -d';' -f2); \
		echo "Setting up region: $$region with cluster name: $$clusterName"; \
		$(MAKE) kube-gke metrics region=$$region clusterName=$$clusterName; \
	done
#FIXME: run the sub-make directly on the gke makefile to avoid variable clashes
#TODO: add metrics & clean-metrics

.PHONY: gcp-firewall
gcp-firewall:
	set -e; \
	ipRanges=""; \
	networkTags=""; \
	for region_cluster in $(regions_clusters); do \
		region=$$(echo $$region_cluster | cut -d';' -f1); \
		clusterName=$$(echo $$region_cluster | cut -d';' -f2); \
		nodeName=$$(kubectl get nodes -o name --output jsonpath={.items[0].metadata.name} --context gke_$(project)_"$$region"_"$$clusterName"); \
		echo Nodename $$nodeName; \
		zone=$$(kubectl get node $$nodeName -o jsonpath="{.metadata.labels['topology\.gke\.io/zone']}" --context gke_$(project)_"$$region"_"$$clusterName"); \
		echo Zone $$zone;\
		networkTag=$$(gcloud compute instances describe $$nodeName --zone $$zone --project $(project) --format="get(tags.items)" ); \
		echo NetworkTag $$networkTag; \
		ipRange=$$(gcloud container clusters describe $$clusterName --region $$region --project $(project) --format='value(clusterIpv4Cidr)'); \
		echo IPrange $$ipRange;\
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
	gcloud compute firewall-rules create $(firewallRule) --direction=INGRESS --priority=999 --network=default --action=ALLOW --rules=tcp:9600,tcp:26501,tcp:26502,tcp:9300,tcp:9200,udp:26502,udp:9300,udp:9200 --source-ranges=$$ipRanges --target-tags=$$networkTags --project $(project)

.PHONY: gcp-dns-chaining
gcp-dns-chaining:
	python3 ../setup-dns-chaining.py $(project) '$(regions_clusters)' $(brokersPerRegion)
## TODO teardown

.PHONY: gcp-bucket
gcp-bucket:
	gcloud storage buckets create gs://$(bucketName) --project $(project)
	gcloud iam service-accounts create $(bucketName)-sa \
    --description="Service account for $(bucketName) bucket" \
    --project $(project)
	gcloud projects add-iam-policy-binding $(project) \
    --member="serviceAccount:$(bucketName)-sa@$(project).iam.gserviceaccount.com" \
    --role="roles/storage.admin"
	gcloud iam service-accounts keys create ../generated/$(bucketName)-backup-key.json \
     --iam-account=$(bucketName)-sa@$(project).iam.gserviceaccount.com

gcp-gcs-secret:
	for region_cluster in $(regions_clusters); do \
		region=$$(echo $$region_cluster | cut -d';' -f1); \
		clusterName=$$(echo $$region_cluster | cut -d';' -f2); \
		kubectl create secret generic gcs-backup-key --from-file=gcs_backup_key.json=../generated/$(bucketName)-backup-key.json --context gke_$(project)_"$$region"_"$$clusterName"; \
	done;

.PHONY: gcp-register-backup-repo
gcp-register-backup-repo:
	@echo "Starting port-forwarding to svc/camunda-elasticsearch..."
	@kubectl port-forward svc/camunda-elasticsearch 9200:9200 & \
	PID=$$!; \
	echo "Waiting for port-forwarding to be ready..."; \
	while ! curl -s -o /dev/null -w "%{http_code}" localhost:9200 | grep -q "200"; do sleep 1; done; \
	echo "Executing backup command..."; \
	status_code=$$(curl --silent --location --request PUT "http://localhost:9200/_snapshot/camunda_backup" \
	--header "Content-Type: application/json" \
	--data-raw "{\"type\": \"gcs\", \"settings\": {\"client\": \"default\", \"bucket\": \"$(bucketName)\", \"compress\": true}}" \
	-o /dev/null -w "%{http_code}"); \
	if [ $$status_code -eq 200 ]; then \
		echo "Backup repository registered successfully."; \
	else \
		echo "Failed to register backup repository. Status code: $$status_code"; \
		exit 1; \
	fi; \
	echo "Stopping port-forwarding..."; \
	kill $$PID

include $(root)/google/include/kubernetes-gke.mk
include $(root)/include/camunda.mk
include $(root)/metrics/metrics.mk

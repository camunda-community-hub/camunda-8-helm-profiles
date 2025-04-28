# TODO move this to ingress-nginx or helm chart
camunda-values.yaml:
	sed "s/127.0.0.1/$(ipAddress)/g;" camunda-values.tpl.yaml > camunda-values.yaml

.PHONY: clean-files
clean-files:
	rm -f .disks
	rm -f camunda-values.yaml

# TODO maybe make initial cluster size bigger so that `helm install` doesn't have to wait for the autoscaler to spin up nodes
.PHONY: kube-gke
kube-gke:
	gcloud config set project $(project)
	gcloud container clusters create $(clusterName) \
	  --region $(region) \
	  --num-nodes=1 \
	  --enable-autoscaling --total-max-nodes=$(maxSize) --total-min-nodes=$(minSize) \
	  --enable-ip-alias \
	  --machine-type=$(machineType) \
	  --spot \
	  --maintenance-window=4:00 \
	  --release-channel=regular \
	  --cluster-version=latest
	gcloud container clusters list
	kubectl apply -f $(root)/google/include/ssd-storageclass-gke.yaml
	gcloud config set project $(project)
	gcloud container clusters get-credentials $(clusterName) --region $(region)

.PHONY: kube-node-pool # create an additional Kubernetes node pool
kube-node-pool:
	gcloud beta container node-pools create "pool-$(nodePoolMachineType)" \
	  --project $(project) \
	  --cluster $(clusterName) \
	  --region $(region) \
	  --machine-type "$(nodePoolMachineType)" \
	  --spot \
	  --num-nodes=0 \
	  --enable-autoscaling --total-min-nodes "0" --total-max-nodes $(maxSize) --location-policy "ANY" \
	  --node-taints $(nodePoolTaints) \
	  --enable-autoupgrade \
	  --enable-autorepair \
	  --max-surge-upgrade 0 --max-unavailable-upgrade 1
# C4 requires hyperdisk. Thus letting GKE pick the disk type.
#	  --disk-type "pd-ssd" # this should only be needed for working with local storage, i.e. without PVC \
#	  --disk-size "100" # 100GiB is the default.\
# TODO for faster benchmark startup `--num-nodes` could be iniziallized by Zeebe Tuner with the expected number of Zeebe Brokers, Gateways, and ES nodes

# original commands suggested by Web Console:
# gcloud beta container --project "camunda-researchanddevelopment" node-pools create "pool-c3-standard-8" --cluster "falko-benchmark" --zone "europe-west1-b" --node-version "1.27.3-gke.1700"    --machine-type "c3-standard-8" --image-type "COS_CONTAINERD" --disk-type "pd-ssd"             --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --spot                 --enable-autoscaling --total-min-nodes "0" --total-max-nodes "64"  --location-policy "ANY" --enable-autoupgrade --enable-autorepair --max-surge-upgrade 0 --max-unavailable-upgrade 1
# gcloud beta container --project "camunda-researchanddevelopment" node-pools create "pool-c4-standard-8" --cluster "falko-benchmark" --zone "europe-west1-b" --node-version "1.30.3-gke.1969001" --machine-type "c4-standard-8" --image-type "COS_CONTAINERD" --disk-type "hyperdisk-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --spot --num-nodes "1" --enable-autoscaling --min-nodes "0"       --max-nodes "256"       --location-policy "ANY" --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0
# gcloud beta container --project "camunda-researchanddevelopment" node-pools create "pool-c4-standard-4" --cluster "falko-benchmark" --zone "europe-west1-b" --node-version "1.31.6-gke.1020000" --machine-type "c4-standard-4" --image-type "COS_CONTAINERD" --disk-type "hyperdisk-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --spot --num-nodes "0" --enable-autoscaling --total-min-nodes "0" --total-max-nodes "256" --location-policy "ANY" --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --shielded-integrity-monitoring --shielded-secure-boot

.PHONY: kube-nodes-allocatable
kube-nodes-allocatable: use-kube
	kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory

.PHONY: clean-kube-gke
clean-kube-gke: use-kube
#	-kubectl delete pvc --all
	@echo "Please check the console if all PVCs have been deleted: https://console.cloud.google.com/compute/disks?authuser=0&project=$(project)&supportedpurview=project"
	gcloud container clusters delete $(clusterName) --region $(region) --async --quiet
	gcloud container clusters list

.PHONY: clean-kube-node-pool
clean-kube-node-pool:
	gcloud container node-pools delete "pool-$(nodePoolMachineType)" --cluster $(clusterName) --region $(region) --quiet

.PHONY: use-kube
use-kube:
	gcloud config set project $(project)
	gcloud container clusters get-credentials $(clusterName) --region $(region)

.PHONY: urls
urls:
	@echo "Cluster: https://console.cloud.google.com/kubernetes/clusters/details/$(region)/$(clusterName)/details?project=$(project)"
	@echo "Workloads: https://console.cloud.google.com/kubernetes/workload_/gcloud/$(region)/$(clusterName)?project=$(project)"

# List pvcs associated with the cluster
.PHONY: disks
disks:
	gcloud compute disks list --filter="zone ~ $(region) AND users ~ $(clusterName) AND name ~ pvc"

.PHONY: create-clound-dns
create-cloud-dns: fqdn
	gcloud dns record-sets create $(fqdn) \
	  --rrdatas=$(IP) \
	  --ttl=30 \
	  --type=A \
	  --zone=$(dnsManagedZone)

.PHONY: delete-cloud-dns
delete-cloud-dns: fqdn
	-gcloud dns record-sets delete $(fqdn) \
	  --type=A \
	  --zone=$(dnsManagedZone)

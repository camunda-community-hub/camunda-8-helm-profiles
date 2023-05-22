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
	@echo "INFO: gcloud set project to $(project)"
	gcloud config set project $(project)
	@echo "INFO: gcloud create cluster  $(clusterName) takes 5 minutes"
	gcloud container clusters create $(clusterName) \
	  --region $(region) \
	  --num-nodes=1 \
	  --enable-autoscaling --max-nodes=$(maxSize) --min-nodes=$(minSize) \
	  --enable-ip-alias \
	  --machine-type=$(machineType) \
	  --disk-type "pd-ssd" \
	  --spot \
	  --maintenance-window=4:00 \
	  --release-channel=regular \
	  --cluster-version=latest
	gcloud container clusters list
	kubectl apply -f $(root)/google/include/ssd-storageclass-gke.yaml
	gcloud config set project $(project)
	gcloud container clusters get-credentials $(clusterName) --region $(region)


.PHONY: clean-kube-gke
clean-kube-gke: use-kube
#	-kubectl delete pvc --all
	@echo "Please check the console if all PVCs have been deleted: https://console.cloud.google.com/compute/disks?authuser=0&project=$(project)&supportedpurview=project"
	gcloud container clusters delete $(clusterName) --region $(region) --async --quiet
	gcloud container clusters list

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

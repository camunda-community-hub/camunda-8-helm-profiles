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
	  --enable-autoscaling --max-nodes=$(maxSize) --min-nodes=$(minSize) \
	  --enable-ip-alias \
	  --machine-type=$(machineType) \
	  --disk-type "pd-ssd" \
	  --preemptible \
	  --maintenance-window=4:00 \
	  --release-channel=regular \
	  --cluster-version=latest
	kubectl apply -f $(root)/google/include/ssd-storageclass-gke.yaml
	gcloud config set project $(project)
	gcloud container clusters get-credentials $(clusterName) --region $(region)


.PHONY: clean-kube-gke
clean-kube: use-kube
#	-kubectl delete pvc --all
	@echo "Please check the console if all PVCs have been deleted: https://console.cloud.google.com/compute/disks?authuser=0&project=$(project)&supportedpurview=project"
	gcloud container clusters delete $(clusterName) --region $(region) --async --quiet

.PHONY: use-kube
use-kube:
	gcloud config set project $(project)
	gcloud container clusters get-credentials $(clusterName) --region $(region)

.PHONY: urls
urls:
	@echo "Cluser: https://console.cloud.google.com/kubernetes/clusters/details/$(REGION)/$(CLUSTER_NAME)/details?project=$(PROJECT)"
	@echo "Workloads: https://console.cloud.google.com/kubernetes/workload/overview?project=$(PROJECT)&pageState=(%22savedViews%22:(%22i%22:%221cd686805f0e43189d3b33934863017b%22,%22c%22:%5B%22gke%2F$(REGION)%2F$(CLUSTER_NAME)%22%5D,%22n%22:%5B%5D))"

# List pvcs associated with the
.PHONY: disks
disks:
	gcloud compute disks list --filter="zone ~ $(region) AND users ~ $(clusterName) AND name ~ pvc"

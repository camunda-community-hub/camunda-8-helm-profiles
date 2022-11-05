
cluster.yaml:
	sed "s/<YOUR CLUSTER NAME>/$(clusterName)/g; s/<YOUR REGION>/$(region)/g; s/<YOUR INSTANCE TYPE>/$(machineType)/g; s/<YOUR MIN SIZE>/$(minSize)/g; s/<YOUR MAX SIZE>/$(maxSize)/g; s/<YOUR AVAILABILITY ZONES>/$(zones)/g; s/<YOUR VOLUME SIZE>/$(volumeSize)/g;" $(root)/aws/include/cluster.tpl.yaml > cluster.yaml

.PHONY: clean-files
clean-files:
	rm -f cluster.yaml

.PHONY: oidc-provider
oidc-provider:
	eksctl utils associate-iam-oidc-provider --cluster $(clusterName) --approve --region $(region)

.PHONY: kube-aws
kube-aws: cluster.yaml
	eksctl create cluster -f cluster.yaml
	# eksctl upgrade cluster --name=$(clusterName) --version=$(clusterVersion)
	kubectl apply -f $(root)/aws/include/ssd-storageclass-aws.yaml

.PHONY: clean-kube-aws
clean-kub-awse: use-kube
	eksctl delete cluster --name $(clusterName) --region $(region)

.PHONY: use-kube
use-kube:
	eksctl utils write-kubeconfig -c $(clusterName) --region $(region)

.PHONY: urls
urls:
	@echo "Cluster: https://us-east-1.console.aws.amazon.com/eks/home?region=us-east-1#/clusters/$(clusterName)"

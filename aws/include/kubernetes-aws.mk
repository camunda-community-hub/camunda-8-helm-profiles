
cluster.yaml:
	sed "s/<YOUR CLUSTER NAME>/$(clusterName)/g; s/<YOUR REGION>/$(region)/g; s/<YOUR INSTANCE TYPE>/$(machineType)/g; s/<YOUR MIN SIZE>/$(minSize)/g; s/<YOUR DESIRED SIZE>/$(desiredSize)/g; s/<YOUR MAX SIZE>/$(maxSize)/g; s/<YOUR AVAILABILITY ZONES>/$(zones)/g; s/<YOUR VOLUME SIZE>/$(volumeSize)/g;" $(root)/aws/include/cluster.tpl.yaml > cluster.yaml

.PHONY: clean-cluster-yaml
clean-cluster-yaml:
	rm -rf cluster.yaml

.PHONY: oidc-provider
oidc-provider:
	eksctl utils associate-iam-oidc-provider --cluster $(clusterName) --approve --region $(region)

#https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
.PHONY: ebs-csi-controller-addon
ebs-csi-controller-addon: ebs-csi-attach-role-policy create-ebs-csi-addon annotate-ebs-csi-sa restart-ebs-csi-controller

.PHONY: fetch-id-values
fetch-id-values:
	$(eval oidc_id := $(shell aws eks describe-cluster --name $(clusterName) --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5))
	$(eval account_id_value := $(shell aws sts get-caller-identity | grep Account | cut -d ':' -f 2))
	$(eval account_id := $(shell echo $(account_id_value) | tr -d ',' ))

.PHONY: create-ebs-csi-controller-role-def
create-ebs-csi-controller-role-def:fetch-id-values
# 1. Fetch OIDC Provider id and AccountId, and create the aws-ebs-csi-driver-trust-policy.json file
	sed "s/<account_id>/$(account_id)/g; s/<region>/$(region)/g; s/<oidc_id>/$(oidc_id)/g;" ebs-csi-driver-trust-policy-template.json > ebs-csi-driver-trust-policy.json

.PHONY: create-ebs-csi-role
create-ebs-csi-role: create-ebs-csi-controller-role-def
# 2. Create the IAM Role - to be run only once, the script will throw error if the role exists already
	aws iam create-role \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName) \
	  --assume-role-policy-document file://"ebs-csi-driver-trust-policy.json"

.PHONY: ebs-csi-attach-role-policy
ebs-csi-attach-role-policy: create-ebs-csi-role
# 3.Attach the role to the IAM policy
	aws iam attach-role-policy \
	  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName)

.PHONY: create-ebs-csi-addon
create-ebs-csi-addon: fetch-id-values
# 4. Add the aws-ebs-csi-driver addon to the cluster
	aws eks create-addon --cluster-name $(clusterName) --addon-name aws-ebs-csi-driver \
	  --service-account-role-arn arn:aws:iam::$(account_id):role/AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName)

.PHONY: annotate-ebs-csi-sa
annotate-ebs-csi-sa: fetch-id-values
# 5. Annotate the ebs-csi-controller-sa svc account
	kubectl annotate serviceaccount ebs-csi-controller-sa \
		-n kube-system \
		eks.amazonaws.com/role-arn=arn:aws:iam::$(account_id):role/AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName) \
		--overwrite

.PHONY: restart-ebs-csi-controller
restart-ebs-csi-controller:
# 6. Restart ebs-csi-controller  if required
	kubectl rollout restart deployment ebs-csi-controller -n kube-system

.PHONY: kube-aws
kube-aws: cluster.yaml
	eksctl create cluster -f cluster.yaml
	# eksctl upgrade cluster --name=$(clusterName) --version=$(clusterVersion)
	kubectl apply -f $(root)/aws/include/ssd-storageclass-aws.yaml
	kubectl patch storageclass ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

.PHONY: detach-role-policy-mapping
detach-role-policy-mapping:
	aws iam detach-role-policy \
	  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName)

.PHONY: delete-iam-role
delete-iam-role: detach-role-policy-mapping
	aws iam delete-role \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName)
	rm ebs-csi-driver-trust-policy.json

.PHONY: clean-kube-aws
clean-kube-aws: clean-cluster-yaml delete-iam-role use-kube
	eksctl delete cluster --name $(clusterName) --region $(region)

.PHONY: use-kube
use-kube:
	eksctl utils write-kubeconfig -c $(clusterName) --region $(region)

.PHONY: urls
urls:
	@echo "Cluster: https://$(region).console.aws.amazon.com/eks/home?region=$(region)#/clusters/$(clusterName)"

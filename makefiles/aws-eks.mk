cluster.yaml:
	@# 1. Strip original brackets, quotes, and spaces
	@# 2. Use sed to wrap each item in single quotes: item1,item2 -> 'item1','item2'
	$(eval FORMATTED_ZONES := $(shell echo $(ZONES) | sed "s/[][ ']//g" | sed "s/,/','/g" | sed "s/^/'/" | sed "s/$$/'/"))

	sed "s/<YOUR CLUSTER NAME>/$(DEPLOYMENT_NAME)/g; \
	     s/<YOUR CLUSTER VERSION>/$(CLUSTER_VERSION)/g; \
	     s/<YOUR REGION>/$(REGION)/g; \
	     s/<YOUR INSTANCE TYPE>/$(MACHINE_TYPE)/g; \
	     s/<YOUR MIN SIZE>/$(MIN_SIZE)/g; \
	     s/<YOUR DESIRED SIZE>/$(DESIRED_SIZE)/g; \
	     s/<YOUR MAX SIZE>/$(MAX_SIZE)/g; \
	     s/<YOUR VOLUME SIZE>/$(VOLUME_SIZE)/g; \
	     s|<YOUR AVAILABILITY ZONES>|[$(FORMATTED_ZONES)]|g;" \
	     $(root)/aws/include/cluster.tpl.yaml > cluster.yaml

.PHONY: clean-cluster-yaml
clean-cluster-yaml:
	rm -rf cluster.yaml

.PHONY: oidc-provider
oidc-provider:
	eksctl utils associate-iam-oidc-provider --cluster $(DEPLOYMENT_NAME) --approve --region $(REGION)

.PHONY: install-ebs-csi-controller-addon
install-ebs-csi-controller-addon:
ifeq "1.23" "$(word 1, $(sort 1.23 $(CLUSTER_VERSION)))"
	@echo "need to install ebs-csi-controller-addon";
	$(MAKE) ebs-csi-controller-addon
endif

#https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
.PHONY: ebs-csi-controller-addon
ebs-csi-controller-addon: ebs-csi-attach-role-policy create-ebs-csi-addon annotate-ebs-csi-sa restart-ebs-csi-controller

.PHONY: fetch-id-values
fetch-id-values:
	$(eval oidc_id := $(shell aws eks describe-cluster --name $(DEPLOYMENT_NAME) --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5))
	$(eval account_id_value := $(shell aws sts get-caller-identity | grep Account | cut -d ':' -f 2))
	$(eval account_id := $(shell echo $(account_id_value) | tr -d ',' ))

.PHONY: create-ebs-csi-controller-role-def
create-ebs-csi-controller-role-def:fetch-id-values
# 1. Fetch OIDC Provider id and AccountId, and create the aws-ebs-csi-driver-trust-policy.json file
	sed "s/<account_id>/$(account_id)/g; s/<region>/$(REGION)/g; s/<oidc_id>/$(oidc_id)/g;" $(root)/aws/include/ebs-csi-driver-trust-policy-template.json > ebs-csi-driver-trust-policy.json

.PHONY: create-ebs-csi-role
create-ebs-csi-role: create-ebs-csi-controller-role-def
# 2. Create the IAM Role - to be run only once, the script will throw error if the role exists already
	aws iam create-role \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(DEPLOYMENT_NAME) \
	  --assume-role-policy-document file://"ebs-csi-driver-trust-policy.json";
	@echo "waiting 20 seconds to create the required role";
	@sleep 20;

.PHONY: ebs-csi-attach-role-policy
ebs-csi-attach-role-policy: create-ebs-csi-role
# 3.Attach the role to the IAM policy
	aws iam attach-role-policy \
	  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(DEPLOYMENT_NAME)

.PHONY: create-ebs-csi-addon
create-ebs-csi-addon: fetch-id-values
# 4. Add the aws-ebs-csi-driver addon to the cluster
	aws eks create-addon --cluster-name $(DEPLOYMENT_NAME) --addon-name aws-ebs-csi-driver \
	  --service-account-role-arn arn:aws:iam::$(account_id):role/AmazonEKS_EBS_CSI_DriverRole_Cluster_$(DEPLOYMENT_NAME);
	@echo "waiting 20 seconds to create the aws-ebs-csi-driver addon";
	@sleep 20;

.PHONY: annotate-ebs-csi-sa
annotate-ebs-csi-sa: fetch-id-values
# 5. Annotate the ebs-csi-controller-sa svc account
	kubectl annotate serviceaccount ebs-csi-controller-sa \
		-n kube-system \
		eks.amazonaws.com/role-arn=arn:aws:iam::$(account_id):role/AmazonEKS_EBS_CSI_DriverRole_Cluster_$(DEPLOYMENT_NAME) \
		--overwrite

.PHONY: restart-ebs-csi-controller
restart-ebs-csi-controller:
# 6. Restart ebs-csi-controller  if required
	kubectl rollout restart deployment ebs-csi-controller -n kube-system

.PHONY: kube-aws
kube-aws: cluster.yaml
	eksctl create cluster -f cluster.yaml
	rm -f $(root)/aws/ingress/nginx/tls/cluster.yaml
	kubectl apply -f $(root)/aws/include/ssd-storageclass-aws.yaml
	kubectl patch storageclass ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

.PHONY: kube
kube: kube-aws install-ebs-csi-controller-addon oidc-provider

.PHONY: kube-upgrade
kube-upgrade:
	eksctl upgrade cluster --name=$(DEPLOYMENT_NAME) --version=$(CLUSTER_VERSION) --approve

.PHONY: detach-role-policy-mapping
detach-role-policy-mapping:
	-aws iam detach-role-policy \
	  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(DEPLOYMENT_NAME)

.PHONY: delete-iam-role
delete-iam-role: detach-role-policy-mapping
	-aws iam delete-role \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(DEPLOYMENT_NAME)
	-rm ebs-csi-driver-trust-policy.json

.PHONY: clean-kube-aws
clean-kube-aws: use-kube clean-cluster-yaml delete-iam-role
	eksctl delete cluster --name $(DEPLOYMENT_NAME) --region $(REGION)

.PHONY: clean-kube
clean-kube: clean-kube-aws

.PHONY: use-kube
use-kube:
	eksctl utils write-kubeconfig -c $(DEPLOYMENT_NAME) --region $(REGION)

.PHONY: urls
urls:
	@echo "Cluster: https://$(REGION).console.aws.amazon.com/eks/home?region=$(REGION)#/clusters/$(DEPLOYMENT_NAME)"

.PHONY: ingress-nginx
ingress-nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait


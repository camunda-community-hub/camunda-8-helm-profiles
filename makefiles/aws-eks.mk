cluster.yaml: clean-cluster-yaml
	sed "s/<DEPLOYMENT_NAME>/$(DEPLOYMENT_NAME)/g; \
	     s/<CLUSTER_VERSION>/$(CLUSTER_VERSION)/g; \
	     s/<REGION>/$(AWS_REGION)/g; \
	     s/<MACHINE_TYPE>/$(AWS_MACHINE_TYPE)/g; \
	     s/<MIN_SIZE>/$(MIN_SIZE)/g; \
	     s/<DESIRED_SIZE>/$(DESIRED_SIZE)/g; \
	     s/<MAX_SIZE>/$(MAX_SIZE)/g; \
	     s/<VOLUME_SIZE>/$(VOLUME_SIZE)/g; \
	     s|<ZONES>|[$(AWS_ZONES)]|g;" \
	     $(root)/recipes/aws/include/cluster.tpl.yaml > cluster.yaml

.PHONY: clean-cluster-yaml
clean-cluster-yaml:
	rm -rf cluster.yaml

.PHONY: oidc-provider
oidc-provider:
	eksctl utils associate-iam-oidc-provider --cluster $(DEPLOYMENT_NAME) --approve --region $(AWS_REGION)

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
	@echo "Fetching OIDC and account identifiers..."
	$(eval oidc_id := $(shell aws eks describe-cluster --name $(DEPLOYMENT_NAME) --region $(AWS_REGION) --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5))
	$(eval account_id_value := $(shell aws sts get-caller-identity | grep Account | cut -d ':' -f 2))
	$(eval account_id := $(shell echo $(account_id_value) | tr -d ',' ))

.PHONY: create-ebs-csi-controller-role-def
create-ebs-csi-controller-role-def:fetch-id-values
# 1. Fetch OIDC Provider id and AccountId, and create the aws-ebs-csi-driver-trust-policy.json file
	sed "s/<account_id>/$(account_id)/g; s/<region>/$(AWS_REGION)/g; s/<oidc_id>/$(oidc_id)/g;" $(root)/recipes/aws/include/ebs-csi-driver-trust-policy-template.json > ebs-csi-driver-trust-policy.json

.PHONY: create-ebs-csi-role
create-ebs-csi-role: create-ebs-csi-controller-role-def
# 2. Create the IAM Role - to be run only once, the script will throw error if the role exists already
	-aws iam create-role \
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
	aws eks create-addon --cluster-name $(DEPLOYMENT_NAME) --region $(AWS_REGION) --addon-name aws-ebs-csi-driver \
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
	kubectl apply -f $(root)/recipes/aws/include/ssd-storageclass-aws.yaml
	kubectl patch storageclass ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

.PHONY: kube
kube: kube-aws oidc-provider install-ebs-csi-controller-addon

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
	eksctl delete cluster --name $(DEPLOYMENT_NAME) --region $(AWS_REGION)

.PHONY: clean-kube
clean-kube: clean-kube-aws

.PHONY: use-kube
use-kube:
	eksctl utils write-kubeconfig -c $(DEPLOYMENT_NAME) --region $(AWS_REGION)

.PHONY: urls
urls:
	@echo "Cluster: https://$(AWS_REGION).console.aws.amazon.com/eks/home?region=$(AWS_REGION)#/clusters/$(DEPLOYMENT_NAME)"

.PHONY: ingress-nginx
ingress-nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait

.PHONY: check-aws-cli
check-aws-cli:
	@echo "Checking AWS authentication..."
	@aws sts get-caller-identity --query "Arn" --output text > /dev/null 2>&1 || \
		(echo "❌ Error: AWS token is expired or missing. Run 'aws sso login' or refresh your credentials." && exit 1)
	@echo "✅ AWS session is valid: $$(aws sts get-caller-identity --query 'Arn' --output text)"

# ════════════════════════════════════════════════════════════════════════════
# DUAL-REGION TARGETS
# ════════════════════════════════════════════════════════════════════════════
#
# These targets extend camunda.mk for dual-region deployments.
# They reuse the existing camunda, create-camunda-credentials, and clean-camunda
# targets by switching kubectl context and overriding CAMUNDA_NAMESPACE.
#
# Prerequisites:
#   - Two Kubernetes clusters with DNS chaining configured
#   - kubectl contexts set for both clusters
#   - CLUSTER_0, CLUSTER_1, CAMUNDA_NAMESPACE_0, CAMUNDA_NAMESPACE_1 defined in config.mk
#
# Usage:
#   make deploy-region0        # Deploy to region 0
#   make deploy-region1        # Deploy to region 1 (can run in parallel)
#   make deploy-dual-region    # Deploy to both regions sequentially
#   make clean-dual-region     # Remove from both regions
#
## ── Dual-Region Variables ──────────────────────────────────────────────────
#CLUSTER_0 ?=
#CLUSTER_1 ?=
#CAMUNDA_NAMESPACE_0 ?= camunda-region0
#CAMUNDA_NAMESPACE_1 ?= camunda-region1
#
## Dual-region cluster sizing (override in config.mk)
#CAMUNDA_CLUSTER_SIZE_DR ?= 4
#CAMUNDA_REPLICATION_FACTOR_DR ?= 4
#CAMUNDA_PARTITION_COUNT_DR ?= 4
#BROKERS_PER_REGION := $(shell echo $$(( $(CAMUNDA_CLUSTER_SIZE_DR) / 2 )))
#
## Generate Zeebe initial contact points for all brokers across both regions
#define generate_contact_points
#$(shell \
#  points=""; sep=""; \
#  for i in $$(seq 0 $$(( $(BROKERS_PER_REGION) - 1 )) ); do \
#    points="$${points}$${sep}$(CAMUNDA_RELEASE_NAME)-zeebe-$${i}.$(CAMUNDA_RELEASE_NAME)-zeebe.$(CAMUNDA_NAMESPACE_0).svc.cluster.local:26502"; \
#    sep=","; \
#    points="$${points}$${sep}$(CAMUNDA_RELEASE_NAME)-zeebe-$${i}.$(CAMUNDA_RELEASE_NAME)-zeebe.$(CAMUNDA_NAMESPACE_1).svc.cluster.local:26502"; \
#  done; \
#  echo "$$points" \
#)
#endef
#
#ZEEBE_INITIAL_CONTACT_POINTS = $(call generate_contact_points)
#
## ── Deploy targets ─────────────────────────────────────────────────────────
## Each target: switches context → copies region values → calls existing targets
#
#.PHONY: deploy-region0
#deploy-region0: camunda-values-region0.yaml
#	@echo "🚀 Deploying Camunda to region 0 ($(CLUSTER_0) / $(CAMUNDA_NAMESPACE_0))..."
#	kubectl config use-context $(CLUSTER_0)
#	cp camunda-values-region0.yaml camunda-values.yaml
#	$(MAKE) create-camunda-credentials camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_0)
#
#.PHONY: deploy-region1
#deploy-region1: camunda-values-region1.yaml
#	@echo "🚀 Deploying Camunda to region 1 ($(CLUSTER_1) / $(CAMUNDA_NAMESPACE_1))..."
#	kubectl config use-context $(CLUSTER_1)
#	cp camunda-values-region1.yaml camunda-values.yaml
#	$(MAKE) create-camunda-credentials camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_1)
#
#.PHONY: deploy-dual-region
#deploy-dual-region: deploy-region0 deploy-region1
#
## ── Region-specific values generation ──────────────────────────────────────
## Generates a dual-region base values file using CAMUNDA_HELM_VALUES_DR,
## then substitutes <REGION_ID> for each region.
#
#camunda-values-dr-base.yaml: delete-camunda-values
#	@echo "📝 Generating dual-region base values..."
#	yq eval-all '. as $$item ireduce ({}; . * $$item)' $(CAMUNDA_HELM_VALUES_DR) | \
#	sed "s|<CAMUNDA_VERSION>|$(CAMUNDA_VERSION)|g; \
#	     s|<CAMUNDA_CLUSTER_SIZE>|$(CAMUNDA_CLUSTER_SIZE_DR)|g; \
#	     s|<CAMUNDA_REPLICATION_FACTOR>|$(CAMUNDA_REPLICATION_FACTOR_DR)|g; \
#	     s|<CAMUNDA_PARTITION_COUNT>|$(CAMUNDA_PARTITION_COUNT_DR)|g; \
#	     s|<CAMUNDA_RELEASE_NAME>|$(CAMUNDA_RELEASE_NAME)|g; \
#	     s|<POSTGRES_HOST>|$(POSTGRES_HOST)|g; \
#	     s|<POSTGRES_CAMUNDA_DB>|$(POSTGRES_CAMUNDA_DB)|g; \
#	     s|<POSTGRES_CAMUNDA_USERNAME>|$(POSTGRES_CAMUNDA_USERNAME)|g; \
#	     s|<ZEEBE_INITIAL_CONTACT_POINTS>|$(ZEEBE_INITIAL_CONTACT_POINTS)|g; \
#	     s|<DEFAULT_PASSWORD>|$(DEFAULT_PASSWORD)|g;" \
#	     > camunda-values-dr-base.yaml
#
#camunda-values-region0.yaml: camunda-values-dr-base.yaml
#	@echo "📝 Generating region 0 values..."
#	sed 's|<REGION_ID>|0|g' camunda-values-dr-base.yaml > camunda-values-region0.yaml
#
#camunda-values-region1.yaml: camunda-values-dr-base.yaml
#	@echo "📝 Generating region 1 values..."
#	sed 's|<REGION_ID>|1|g' camunda-values-dr-base.yaml > camunda-values-region1.yaml
#
## ── Clean targets ──────────────────────────────────────────────────────────
#
#.PHONY: clean-region0
#clean-region0:
#	@echo "🧹 Removing Camunda from region 0..."
#	kubectl config use-context $(CLUSTER_0)
#	$(MAKE) clean-camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_0)
#
#.PHONY: clean-region1
#clean-region1:
#	@echo "🧹 Removing Camunda from region 1..."
#	kubectl config use-context $(CLUSTER_1)
#	$(MAKE) clean-camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_1)
#
#.PHONY: clean-dual-region
#clean-dual-region: clean-region0 clean-region1
#
#.PHONY: clean-dr-generated
#clean-dr-generated:
#	-rm -f camunda-values-dr-base.yaml camunda-values-region0.yaml camunda-values-region1.yaml
#
## ── Verification ───────────────────────────────────────────────────────────
#
#.PHONY: pods-region0
#pods-region0:
#	kubectl --context $(CLUSTER_0) get pods -n $(CAMUNDA_NAMESPACE_0)
#
#.PHONY: pods-region1
#pods-region1:
#	kubectl --context $(CLUSTER_1) get pods -n $(CAMUNDA_NAMESPACE_1)
#
#.PHONY: topology
#topology:
#	@echo "Checking Zeebe topology via region 0..."
#	kubectl --context $(CLUSTER_0) -n $(CAMUNDA_NAMESPACE_0) \
#	  exec svc/$(CAMUNDA_RELEASE_NAME)-zeebe-gateway -- \
#	  curl -sf -u demo:demo http://localhost:8080/v2/topology 2>/dev/null | jq . || \
#	  echo "⚠️  Could not reach Zeebe gateway. Try port-forwarding first."
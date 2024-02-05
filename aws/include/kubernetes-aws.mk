
cluster.yaml:
	-rm -f $(root)/aws/ingress/nginx/tls/cluster.yaml
	sed "s/<YOUR CLUSTER NAME>/$(clusterName)/g; s/<YOUR CLUSTER VERSION>/$(clusterVersion)/g; s/<YOUR REGION>/$(region)/g; s/<YOUR INSTANCE TYPE>/$(machineType)/g; s/<YOUR MIN SIZE>/$(minSize)/g; s/<YOUR DESIRED SIZE>/$(desiredSize)/g; s/<YOUR MAX SIZE>/$(maxSize)/g; s/<YOUR AVAILABILITY ZONES>/$(zones)/g; s/<YOUR VOLUME SIZE>/$(volumeSize)/g;" $(root)/aws/include/cluster.tpl.yaml > cluster.yaml

.PHONY: clean-cluster-yaml
clean-cluster-yaml:
	rm -rf cluster.yaml

.PHONY: oidc-provider
oidc-provider:
	eksctl utils associate-iam-oidc-provider --cluster $(clusterName) --approve --region $(region)

.PHONY: install-eks-cni-addon
install-eks-cni-addon:
	aws eks create-addon --cluster-name $(clusterName) --addon-name vpc-cni --addon-version v1.16.2-eksbuild.1 --region $(region)

.PHONY: install-ebs-csi-controller-addon
install-ebs-csi-controller-addon:
ifeq "1.23" "$(word 1, $(sort 1.23 $(clusterVersion)))"
	@echo "need to install ebs-csi-controller-addon";
	make ebs-csi-controller-addon
endif

#https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
.PHONY: ebs-csi-controller-addon
ebs-csi-controller-addon: ebs-csi-attach-role-policy create-ebs-csi-addon annotate-ebs-csi-sa restart-ebs-csi-controller

.PHONY: fetch-id-values
fetch-id-values:
	$(eval oidc_id := $(shell aws eks describe-cluster --name $(clusterName) --region $(region) --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5))
	$(eval account_id_value := $(shell aws sts get-caller-identity | grep Account | cut -d ':' -f 2))
	$(eval account_id := $(shell echo $(account_id_value) | tr -d ',' ))

.PHONY: create-ebs-csi-controller-role-def
create-ebs-csi-controller-role-def:fetch-id-values
# 1. Fetch OIDC Provider id and AccountId, and create the aws-ebs-csi-driver-trust-policy.json file
	sed "s/<account_id>/$(account_id)/g; s/<region>/$(region)/g; s/<oidc_id>/$(oidc_id)/g;" $(root)/aws/include/ebs-csi-driver-trust-policy-template.json > ebs-csi-driver-trust-policy.json

.PHONY: create-ebs-csi-role
create-ebs-csi-role: create-ebs-csi-controller-role-def
# 2. Create the IAM Role - to be run only once, the script will throw error if the role exists already
	aws iam create-role \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName) \
	  --assume-role-policy-document file://"ebs-csi-driver-trust-policy.json";
	@echo "waiting 20 seconds to create the required role";
	@sleep 20;

.PHONY: ebs-csi-attach-role-policy
ebs-csi-attach-role-policy: create-ebs-csi-role
# 3.Attach the role to the IAM policy
	aws iam attach-role-policy \
	  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName)

.PHONY: create-ebs-csi-addon
create-ebs-csi-addon: fetch-id-values
# 4. Add the aws-ebs-csi-driver addon to the cluster
	aws eks create-addon --cluster-name $(clusterName) --region $(region) --addon-name aws-ebs-csi-driver \
	  --service-account-role-arn arn:aws:iam::$(account_id):role/AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName);
	@echo "waiting 20 seconds to create the aws-ebs-csi-driver addon";
	@sleep 20;

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

.PHONY: describe-vpcs
describe-vpcs:
	aws ec2 describe-vpcs --region $(region)

## ============= create and accept peering connection from region 0 to region 1 ====================
# get the ids of both vpcs
.PHONY: get-vpcs-ids
get-vpcs-ids:
	$(eval vpc_id := $(shell aws ec2 describe-vpcs --region $(region) --query 'Vpcs[0].VpcId' --output text))
	@echo "VPC ID: $(vpc_id)"
	$(eval peer_vpc_id := $(shell aws ec2 describe-vpcs --region $(peerRegion) --query 'Vpcs[0].VpcId' --output text))
	@echo "PEER VPC ID: $(peer_vpc_id)"

# create peering connection between regions
.PHONY: create-peering-connection
create-peering-connection: get-vpcs-ids
	aws ec2 create-vpc-peering-connection --vpc-id $(vpc_id) --peer-vpc-id $(peer_vpc_id) --peer-region $(peerRegion) --region $(region)
	@echo "waiting 20 seconds";
	@sleep 20;

.PHONY: get-peering-connection-id
get-peering-connection-id:
	# $(eval peering_connection_id := $(shell aws ec2 describe-vpc-peering-connections --filters Name=status-code,Values=pending-acceptance --region $(region) --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text))
	$(eval peering_connection_id := $(shell aws ec2 describe-vpc-peering-connections --region $(region) --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text))
	@echo "PEERING CONNECTION ID: $(peering_connection_id)"

# accept peering connection between regions
.PHONY: accept-peering-connection
accept-peering-connection: get-peering-connection-id
	aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $(peering_connection_id)

.PHONY: create-dual-region-peering
create-dual-region-peering: create-peering-connection accept-peering-connection

#delete peering connection
.PHONY: delete-peering-connection
delete-peering-connection: get-peering-connection-id
	-aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $(peering_connection_id)


## ============= update route tables in region 0 with cidr from region 1 ====================
#descirbe route tables
.PHONY: describe-route-table
describe-route-table:
	aws ec2 describe-route-tables --region $(region) --output json

# get route table ids region
.PHONY: get-route-table-ids
get-route-table-ids:
	$(eval route_table_ids := $(shell aws ec2 describe-route-tables --region $(region) --output json | jq '.RouteTables[].RouteTableId'))
	@echo "Route table IDs: $(route_table_ids)"

# get destination cidr block
.PHONY: get-destination-cidr-block
get-destination-cidr-block:
	$(eval destination_cidr_block := $(shell aws ec2 describe-vpcs --region $(peerRegion) --query 'Vpcs[0].CidrBlock' --output text))
	@echo "destination_cidr_block: $(destination_cidr_block)"

# update route tables
.PHONY: update-route-tables
update-route-tables: get-peering-connection-id get-route-table-ids get-destination-cidr-block
	@$(foreach route_table_id,$(route_table_ids),aws ec2 create-route --route-table-id $(route_table_id) --destination-cidr-block $(destination_cidr_block) --vpc-peering-connection-id $(peering_connection_id) --region $(region);)

## ============= update route tables in region 1 with cidr from region 0 ====================
# get route table ids region_1
# .PHONY: get-route-table-ids-region-1
# get-route-table-ids-region-1:
# 	$(eval route_table_ids := $(shell aws ec2 describe-route-tables --region $(region_1) --output json | jq '.RouteTables[].RouteTableId'))
# 	@echo "Route table IDs: $(route_table_ids)"

# get destination cidr block region 0
# .PHONY: get-destination_cidr_block-region-0
# get-destination_cidr_block-region-0:
# 	$(eval destination_cidr_block := $(shell aws ec2 describe-vpcs --region $(region) --query 'Vpcs[0].CidrBlock' --output text))
# 	@echo "destination_cidr_block: $(destination_cidr_block)"

# update route tables
# .PHONY: update-route-tables-region_1
# update-route-tables-region_1: get-peering-connection-id get-route-table-ids-region-1 get-destination_cidr_block-region-0
# 	@$(foreach route_table_id,$(route_table_ids),aws ec2 create-route --route-table-id $(route_table_id) --destination-cidr-block $(destination_cidr_block) --vpc-peering-connection-id $(peering_connection_id) --region $(region_1);)

## ============= update security groups ====================
# get security groups ids for VPC
# NOTE: I get all the rules for the VPC. We only really need to update the rules for the subnets that have nodes
.PHONY: get-vpc-security-group-ids
get-vpc-security-group-ids: get-vpcs-ids
	$(eval security_group_ids := $(shell aws ec2 get-security-groups-for-vpc --region $(region) --vpc-id $(vpc_id) --output json | jq '.SecurityGroupForVpcs[].GroupId'))
	@echo "Security Group IDs: $(security_group_ids)"

# add inbound VPC security group rule
.PHONY: add-inbound-vpc-security-group-rule
add-inbound-vpc-security-group-rule: get-destination-cidr-block get-vpc-security-group-ids
	@$(foreach group_id,$(security_group_ids), \
	aws ec2 authorize-security-group-ingress --region $(region) \
    --group-id $(group_id) \
    --protocol all \
    --port all \
    --cidr $(destination_cidr_block) \
		;)

# add outbound VPC security group rule
.PHONY: add-outbound-vpc-security-group-rule
add-outbound-vpc-security-group-rule: get-destination-cidr-block get-vpc-security-group-ids
	@$(foreach group_id,$(security_group_ids), \
	aws ec2 authorize-security-group-egress --region $(region) \
    --group-id $(group_id) \
    --protocol all \
    --port all \
    --cidr $(destination_cidr_block) \
		;)

# update all inbond and outbound security group rules region 0
.PHONY: update-security-group-rules
update-security-group-rules: get-vpc-security-group-ids add-inbound-vpc-security-group-rule add-outbound-vpc-security-group-rule

## ============= update security groups reion-1 ====================
# get security groups ids for VPC -region-1
# NOTE: I get all the rules for the VPC. We only really need to update the rules for the subnets that have nodes
# .PHONY: get-vpc-security-group-ids-region-1
# get-vpc-security-group-ids-region-1: get-vpcs-ids
# 	$(eval security_group_ids := $(shell aws ec2 get-security-groups-for-vpc --region $(region_1) --vpc-id $(peer_vpc_id) --output json | jq '.SecurityGroupForVpcs[].GroupId'))
# 	@echo "Security Group IDs: $(security_group_ids)"

# add inbound VPC security group rule -region-1
# .PHONY: add-inbound-vpc-security-group-rule-region-1
# add-inbound-vpc-security-group-rule-region-1: get-destination_cidr_block-region-0 get-vpc-security-group-ids-region-1
	# @$(foreach group_id,$(security_group_ids), \
	# aws ec2 authorize-security-group-ingress --region $(region_1) \
  #   --group-id $(group_id) \
  #   --protocol all \
  #   --port all \
  #   --cidr $(destination_cidr_block) \
	# 	;)

# add outbound VPC security group rule -region-1
# .PHONY: add-outbound-vpc-security-group-rule-region-1
# add-outbound-vpc-security-group-rule-region-1: get-destination_cidr_block-region-0 get-vpc-security-group-ids-region-1
# 	@$(foreach group_id,$(security_group_ids), \
# 	aws ec2 authorize-security-group-egress --region $(region_1) \
#     --group-id $(group_id) \
#     --protocol all \
#     --port all \
#     --cidr $(destination_cidr_block) \
# 		;)

# update all inbond and outbound security group rules region 1
# .PHONY: update-seurity-group-rules-region-1
# update-seurity-group-rules-region-1: get-vpc-security-group-ids-region-1 add-inbound-vpc-security-group-rule-region-1 add-outbound-vpc-security-group-rule-region-1

## ============ Update CoreDNS with endpoints from peer cluster =================

#get coredns enpoints for cluster using kubectl
.PHONY: get-coredns-endpoints
get-coredns-endpoints:
	$(eval coredns_endpoints := $(shell kubectl get endpoints kube-dns --namespace=kube-system -o json | jq '.subsets[].addresses[].ip'))
	@echo "CoreDNS Endpoints: $(coredns_endpoints)"

# edit coredns configmap
.PHONY: edit-coredns-configmap
edit-coredns-configmap:
	-rm ./coredns.yaml
	sed "s/<REGION>/$(peerRegion)/g; s/<ENDPOINTS>/$(coredns_endpoints)/g;" $(root)/aws/include/coredns.tpl.yaml > coredns.yaml

# replace coredns configmap
.PHONY: replace-coredns-configmap
replace-coredns-configmap: use-kube-peer get-coredns-endpoints use-kube edit-coredns-configmap
	kubectl replace -n kube-system -f coredns.yaml
	kubectl get configmap coredns -n kube-system -o yaml

## ========Setup Cluster(s)=======================================================

.PHONY: kube-aws
kube-aws: cluster.yaml create-cluster-aws apply-storageclass
	# eksctl create cluster -f cluster.yaml
	rm -f $(root)/aws/ingress/nginx/tls/cluster.yaml
	# kubectl apply -f $(root)/aws/include/ssd-storageclass-aws.yaml
	# kubectl patch storageclass ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	# kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

.PHONY: kube-aws-dual-region
kube-aws-dual-region: multi-region-cluster.yaml create-cluster-aws apply-storageclass

.PHONY: create-cluster-aws
create-cluster-aws:
	eksctl create cluster -f cluster.yaml
	@echo "waiting 20 seconds";
	@sleep 20;

.PHONY: apply-storageclass
	kubectl apply -f $(root)/aws/include/ssd-storageclass-aws.yaml
	kubectl patch storageclass ssd -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
	kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

multi-region-cluster.yaml:
	-rm -f $(root)/aws/multi-region/active-active/dual-region/$(region)/cluster.yaml
	sed "s/<YOUR CLUSTER NAME>/$(clusterName)/g; s/<YOUR CLUSTER VERSION>/$(clusterVersion)/g; s/<YOUR REGION>/$(region)/g; s/<YOUR INSTANCE TYPE>/$(machineType)/g; s/<YOUR MIN SIZE>/$(minSize)/g; s/<YOUR DESIRED SIZE>/$(desiredSize)/g; s/<YOUR MAX SIZE>/$(maxSize)/g; s/<YOUR AVAILABILITY ZONES>/$(zones)/g; s/<YOUR VOLUME SIZE>/$(volumeSize)/g; s/<CIDR BLOCK>/$(cidrBlock)/g; s/<PUBLIC ACCESS>/$(publicAccess)/g;" $(root)/aws/include/multi-region-cluster.tpl.yaml > cluster.yaml

.PHONY: kube
kube: kube-aws install-ebs-csi-controller-addon oidc-provider

.PHONY: kube-dual-region
kube-dual-region: kube-aws-dual-region install-ebs-csi-controller-addon oidc-provider install-eks-cni-addon

.PHONY: kube-upgrade
kube-upgrade:
	eksctl upgrade cluster --name=$(clusterName) --version=$(clusterVersion) --approve

.PHONY: detach-role-policy-mapping
detach-role-policy-mapping:
	-aws iam detach-role-policy \
	  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName)

.PHONY: delete-iam-role
delete-iam-role: detach-role-policy-mapping
	-aws iam delete-role \
	  --role-name AmazonEKS_EBS_CSI_DriverRole_Cluster_$(clusterName)
	-rm ebs-csi-driver-trust-policy.json

.PHONY: clean-kube-aws
clean-kube-aws: use-kube clean-cluster-yaml delete-iam-role
	eksctl delete cluster --name $(clusterName) --region $(region)

.PHONY: clean-kube-region-aws
clean-kube-region-aws: use-kube delete-iam-role delete-peering-connection
	eksctl delete cluster --name $(clusterName) --region $(region)

.PHONY: use-kube
use-kube:
	eksctl utils write-kubeconfig -c $(clusterName) --region $(region)

.PHONY: use-kube-peer
use-kube-peer:
	eksctl utils write-kubeconfig -c $(peerClusterName) --region $(peerRegion)

.PHONY: urls
urls:
	@echo "Cluster: https://$(region).console.aws.amazon.com/eks/home?region=$(region)#/clusters/$(clusterName)"

.PHONY: await-elb
await-elb:
	$(root)/aws/ingress/nginx/tls/aws-ingress.sh

.PHONY: ingress-aws-ip-from-service
ingress-aws-ip-from-service: await-elb
	$(eval ELB_ID := $(shell kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.hostname}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1 | cut -d'.' -f 1 | cut -d'-' -f 1))
	@echo "AWS ELB id: $(ELB_ID)"
	$(eval IP_TMP := $(shell aws ec2 describe-network-interfaces --filters Name=description,Values="ELB ${ELB_ID}" --query 'NetworkInterfaces[0].PrivateIpAddresses[*].Association.PublicIp' --output text))
	#$(eval IP := $(shell echo ${IP_TMP} | sed 's/\./-/g'))
	$(eval IP := $(shell echo ${IP_TMP} ))
	#@echo "AWS ELB IP: ec2-$(IP).compute-1.amazonaws.com"
	@echo "AWS ELB IP: $(IP)"

.PHONY: fqdn-aws
fqdn-aws: ingress-aws-ip-from-service
	$(eval fqdn ?= $(shell if [ "$(baseDomainName)" == "nip.io" ]; then echo "$(dnsLabel).$(IP).$(baseDomainName)"; else echo "$(dnsLabel).$(baseDomainName)"; fi))
	@echo "Fully qualified domain name is: $(fqdn)"

camunda-values-ingress-aws.yaml: fqdn-aws
	sed "s/localhost/$(fqdn)/g;" $(root)/development/camunda-values-with-ingress.yaml > ./camunda-values-ingress-aws.yaml

camunda-values-nginx-tls-aws.yaml: fqdn-aws camunda-values-grock-tls

camunda-values-grock-tls:
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/ingress-nginx/camunda-values.yaml > ./camunda-values-ingress-tls-aws.yaml;

camunda-values-istio-aws.yaml:
	sed "s/YOUR_HOSTNAME/$(dnsLabel).$(baseDomainName)/g;" $(root)/istio/camunda-values.yaml > ./camunda-values-aws.yaml

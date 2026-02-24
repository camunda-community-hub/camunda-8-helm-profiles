# ════════════════════════════════════════════════════════════════════════════
# AWS EKS DUAL-REGION TARGETS
# ════════════════════════════════════════════════════════════════════════════
#
# Extends aws-eks.mk with dual-region infrastructure:
#   - Two-cluster creation (reuses kube target per region)
#   - VPC peering between regions
#   - DNS chaining (CoreDNS cross-cluster forwarding)
#
# Prerequisites:
#   - include $(root)/makefiles/aws-eks.mk  (must be included BEFORE this file)
#   - CLUSTER_0, CLUSTER_1, AWS_REGION_0, AWS_REGION_1 defined in config.mk
#   - VPC_CIDR_0, VPC_CIDR_1 must be non-overlapping
#
# Usage:
#   make create-cluster-region0   # Creates EKS cluster in region 0
#   make create-cluster-region1   # Creates EKS cluster in region 1 (parallel OK)
#   make configure-vpc-peering    # Full VPC peering setup
#   make configure-dns            # DNS chaining between clusters
#   make test-dns                 # Verify cross-region DNS

# ── Dual-Region Variables ──────────────────────────────────────────────────
CLUSTER_0 ?=
CLUSTER_1 ?=
AWS_REGION_0 ?= us-east-1
AWS_REGION_1 ?= us-west-2
VPC_CIDR_0 ?= 10.192.0.0/16
VPC_CIDR_1 ?= 10.193.0.0/16
CAMUNDA_NAMESPACE_0 ?= camunda-region0
CAMUNDA_NAMESPACE_1 ?= camunda-region1

# Override cluster.yaml target from aws-eks.mk to support VPC CIDR
# VPC_CIDR is passed per-region when calling $(MAKE) kube
cluster.yaml: clean-cluster-yaml
	sed "s/<DEPLOYMENT_NAME>/$(DEPLOYMENT_NAME)/g; \
	     s/<CLUSTER_VERSION>/$(CLUSTER_VERSION)/g; \
	     s/<REGION>/$(AWS_REGION)/g; \
	     s/<MACHINE_TYPE>/$(AWS_MACHINE_TYPE)/g; \
	     s/<MIN_SIZE>/$(MIN_SIZE)/g; \
	     s/<DESIRED_SIZE>/$(DESIRED_SIZE)/g; \
	     s/<MAX_SIZE>/$(MAX_SIZE)/g; \
	     s/<VOLUME_SIZE>/$(VOLUME_SIZE)/g; \
	     s|<VPC_CIDR>|$(VPC_CIDR)|g; \
	     s|<ZONES>|[$(AWS_ZONES)]|g;" \
	     $(CLUSTER_TEMPLATE) > cluster.yaml

# Template selection: use dual-region template if it exists, otherwise fall back
CLUSTER_TEMPLATE ?= $(root)/recipes/aws/include/cluster-dual-region.tpl.yaml

# ── Cluster Management ─────────────────────────────────────────────────────
# Reuses kube (kube-aws + oidc + ebs-csi) from aws-eks.mk via DEPLOYMENT_NAME/AWS_REGION override

.PHONY: create-cluster-region0
create-cluster-region0:
	@echo "📦 Creating EKS cluster $(CLUSTER_0) in $(AWS_REGION_0) (CIDR: $(VPC_CIDR_0))..."
	$(MAKE) kube DEPLOYMENT_NAME=$(CLUSTER_0) AWS_REGION=$(AWS_REGION_0) VPC_CIDR=$(VPC_CIDR_0)
	aws eks --region $(AWS_REGION_0) update-kubeconfig --name $(CLUSTER_0) --alias $(CLUSTER_0)

.PHONY: create-cluster-region1
create-cluster-region1:
	@echo "📦 Creating EKS cluster $(CLUSTER_1) in $(AWS_REGION_1) (CIDR: $(VPC_CIDR_1))..."
	$(MAKE) kube DEPLOYMENT_NAME=$(CLUSTER_1) AWS_REGION=$(AWS_REGION_1) VPC_CIDR=$(VPC_CIDR_1)
	aws eks --region $(AWS_REGION_1) update-kubeconfig --name $(CLUSTER_1) --alias $(CLUSTER_1)

.PHONY: clean-cluster-region0
clean-cluster-region0:
	@echo "🗑️  Deleting EKS cluster $(CLUSTER_0)..."
	$(MAKE) clean-kube-aws DEPLOYMENT_NAME=$(CLUSTER_0) AWS_REGION=$(AWS_REGION_0)

.PHONY: clean-cluster-region1
clean-cluster-region1:
	@echo "🗑️  Deleting EKS cluster $(CLUSTER_1)..."
	$(MAKE) clean-kube-aws DEPLOYMENT_NAME=$(CLUSTER_1) AWS_REGION=$(AWS_REGION_1)

# ── VPC Peering ────────────────────────────────────────────────────────────

.PHONY: configure-vpc-peering
configure-vpc-peering: create-vpc-peering accept-vpc-peering configure-vpc-routes configure-vpc-security-groups
	@echo "✅ VPC peering fully configured between $(AWS_REGION_0) and $(AWS_REGION_1)"

.PHONY: create-vpc-peering
create-vpc-peering:
	@echo "🔗 Setting up VPC peering..."
	@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text 2>/dev/null); \
	VPC_CIDR_0=$$(aws ec2 describe-vpcs --region $(AWS_REGION_0) \
	  --vpc-ids $$VPC_ID_0 --query 'Vpcs[0].CidrBlock' --output text); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text 2>/dev/null); \
	VPC_CIDR_1=$$(aws ec2 describe-vpcs --region $(AWS_REGION_1) \
	  --vpc-ids $$VPC_ID_1 --query 'Vpcs[0].CidrBlock' --output text); \
	echo "  Region 0: VPC=$$VPC_ID_0 CIDR=$$VPC_CIDR_0"; \
	echo "  Region 1: VPC=$$VPC_ID_1 CIDR=$$VPC_CIDR_1"; \
	if [ -z "$$VPC_ID_0" ] || echo "$$VPC_ID_0" | grep -q "None\|error"; then \
	  echo "❌ Could not find VPC for cluster $(CLUSTER_0) in $(AWS_REGION_0)"; exit 1; \
	fi; \
	if [ -z "$$VPC_ID_1" ] || echo "$$VPC_ID_1" | grep -q "None\|error"; then \
	  echo "❌ Could not find VPC for cluster $(CLUSTER_1) in $(AWS_REGION_1)"; exit 1; \
	fi; \
	if [ "$$VPC_CIDR_0" = "$$VPC_CIDR_1" ]; then \
	  echo "❌ ERROR: Both VPCs have the same CIDR ($$VPC_CIDR_0). VPC peering requires non-overlapping CIDRs."; \
	  exit 1; \
	fi; \
	EXISTING=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	  --filters "Name=requester-vpc-info.vpc-id,Values=$$VPC_ID_0" \
	            "Name=accepter-vpc-info.vpc-id,Values=$$VPC_ID_1" \
	            "Name=status-code,Values=active,pending-acceptance,provisioning" \
	  --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text); \
	if [ "$$EXISTING" != "None" ] && [ -n "$$EXISTING" ]; then \
	  echo "  ⚠️  Peering already exists: $$EXISTING. Skipping."; \
	else \
	  echo "  Creating VPC peering connection..."; \
	  PEERING_ID=$$(aws ec2 create-vpc-peering-connection --region $(AWS_REGION_0) \
	    --vpc-id $$VPC_ID_0 \
	    --peer-vpc-id $$VPC_ID_1 \
	    --peer-region $(AWS_REGION_1) \
	    --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text); \
	  echo "  ✅ Peering created: $$PEERING_ID"; \
	fi

.PHONY: accept-vpc-peering
accept-vpc-peering:
	@echo "=== Accepting VPC peering ==="
	@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	PEERING_ID=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	  --filters "Name=requester-vpc-info.vpc-id,Values=$$VPC_ID_0" \
	            "Name=accepter-vpc-info.vpc-id,Values=$$VPC_ID_1" \
	  --query 'VpcPeeringConnections[?Status.Code!=`deleted` && Status.Code!=`rejected`] | [0].VpcPeeringConnectionId' --output text); \
	if [ "$$PEERING_ID" = "None" ] || [ -z "$$PEERING_ID" ]; then \
	  echo "❌ No peering connection found. Run 'make create-vpc-peering' first."; exit 1; \
	fi; \
	echo "  Peering ID: $$PEERING_ID"; \
	STATUS=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	  --vpc-peering-connection-ids $$PEERING_ID \
	  --query 'VpcPeeringConnections[0].Status.Code' --output text); \
	if [ "$$STATUS" = "active" ]; then \
	  echo "  ⚠️  Already active. Skipping."; \
	else \
	  echo "  Accepting in $(AWS_REGION_1)..."; \
	  aws ec2 accept-vpc-peering-connection --region $(AWS_REGION_1) \
	    --vpc-peering-connection-id $$PEERING_ID > /dev/null; \
	  echo "  ⏳ Waiting for active status..."; \
	  for i in $$(seq 1 30); do \
	    S=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	      --vpc-peering-connection-ids $$PEERING_ID \
	      --query 'VpcPeeringConnections[0].Status.Code' --output text); \
	    if [ "$$S" = "active" ]; then echo "  ✅ Peering active"; break; fi; \
	    sleep 2; \
	  done; \
	fi

.PHONY: configure-vpc-routes
configure-vpc-routes:
	@echo "=== Configuring route tables ==="
	@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_CIDR_0=$$(aws ec2 describe-vpcs --region $(AWS_REGION_0) \
	  --vpc-ids $$VPC_ID_0 --query 'Vpcs[0].CidrBlock' --output text); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_CIDR_1=$$(aws ec2 describe-vpcs --region $(AWS_REGION_1) \
	  --vpc-ids $$VPC_ID_1 --query 'Vpcs[0].CidrBlock' --output text); \
	PEERING_ID=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	  --filters "Name=requester-vpc-info.vpc-id,Values=$$VPC_ID_0" \
	            "Name=accepter-vpc-info.vpc-id,Values=$$VPC_ID_1" \
	            "Name=status-code,Values=active" \
	  --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text); \
	echo "  Peering: $$PEERING_ID"; \
	echo ""; \
	echo "  --- Region 0: route $$VPC_CIDR_1 → $$PEERING_ID ---"; \
	for RT in $$(aws ec2 describe-route-tables --region $(AWS_REGION_0) \
	    --filters "Name=vpc-id,Values=$$VPC_ID_0" \
	    --query 'RouteTables[*].RouteTableId' --output text); do \
	  aws ec2 create-route --region $(AWS_REGION_0) \
	    --route-table-id $$RT \
	    --destination-cidr-block $$VPC_CIDR_1 \
	    --vpc-peering-connection-id $$PEERING_ID > /dev/null 2>&1 && \
	  echo "    $$RT: ✅ route added" || echo "    $$RT: ⚠️  route exists"; \
	done; \
	echo ""; \
	echo "  --- Region 1: route $$VPC_CIDR_0 → $$PEERING_ID ---"; \
	for RT in $$(aws ec2 describe-route-tables --region $(AWS_REGION_1) \
	    --filters "Name=vpc-id,Values=$$VPC_ID_1" \
	    --query 'RouteTables[*].RouteTableId' --output text); do \
	  aws ec2 create-route --region $(AWS_REGION_1) \
	    --route-table-id $$RT \
	    --destination-cidr-block $$VPC_CIDR_0 \
	    --vpc-peering-connection-id $$PEERING_ID > /dev/null 2>&1 && \
	  echo "    $$RT: ✅ route added" || echo "    $$RT: ⚠️  route exists"; \
	done

.PHONY: configure-vpc-security-groups
configure-vpc-security-groups:
	@echo "=== Configuring security groups ==="
	@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_CIDR_0=$$(aws ec2 describe-vpcs --region $(AWS_REGION_0) \
	  --vpc-ids $$VPC_ID_0 --query 'Vpcs[0].CidrBlock' --output text); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_CIDR_1=$$(aws ec2 describe-vpcs --region $(AWS_REGION_1) \
	  --vpc-ids $$VPC_ID_1 --query 'Vpcs[0].CidrBlock' --output text); \
	echo "  --- Region 0: allow inbound from $$VPC_CIDR_1 ---"; \
	for SG in $$(aws ec2 describe-security-groups --region $(AWS_REGION_0) \
	    --filters "Name=vpc-id,Values=$$VPC_ID_0" \
	    --query "SecurityGroups[?contains(GroupName,'ClusterSharedNode') || contains(GroupName,'eks-cluster-sg')].GroupId" --output text); do \
	  echo "    SG $$SG:"; \
	  for PORT in 53 26500-26502 5432 8080; do \
	    aws ec2 authorize-security-group-ingress --region $(AWS_REGION_0) \
	      --group-id $$SG --protocol tcp --port $$PORT --cidr $$VPC_CIDR_1 2>/dev/null && \
	      echo "      ✅ TCP $$PORT" || echo "      ⚠️  TCP $$PORT (exists)"; \
	  done; \
	  aws ec2 authorize-security-group-ingress --region $(AWS_REGION_0) \
	    --group-id $$SG --protocol udp --port 53 --cidr $$VPC_CIDR_1 2>/dev/null && \
	    echo "      ✅ UDP 53" || echo "      ⚠️  UDP 53 (exists)"; \
	done; \
	echo ""; \
	echo "  --- Region 1: allow inbound from $$VPC_CIDR_0 ---"; \
	for SG in $$(aws ec2 describe-security-groups --region $(AWS_REGION_1) \
	    --filters "Name=vpc-id,Values=$$VPC_ID_1" \
	    --query "SecurityGroups[?contains(GroupName,'ClusterSharedNode') || contains(GroupName,'eks-cluster-sg')].GroupId" --output text); do \
	  echo "    SG $$SG:"; \
	  for PORT in 53 26500-26502 5432 8080; do \
	    aws ec2 authorize-security-group-ingress --region $(AWS_REGION_1) \
	      --group-id $$SG --protocol tcp --port $$PORT --cidr $$VPC_CIDR_0 2>/dev/null && \
	      echo "      ✅ TCP $$PORT" || echo "      ⚠️  TCP $$PORT (exists)"; \
	  done; \
	  aws ec2 authorize-security-group-ingress --region $(AWS_REGION_1) \
	    --group-id $$SG --protocol udp --port 53 --cidr $$VPC_CIDR_0 2>/dev/null && \
	    echo "      ✅ UDP 53" || echo "      ⚠️  UDP 53 (exists)"; \
	done

.PHONY: vpc-peering-status
vpc-peering-status:
	@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	  --filters "Name=requester-vpc-info.vpc-id,Values=$$VPC_ID_0" \
	            "Name=accepter-vpc-info.vpc-id,Values=$$VPC_ID_1" \
	  --query 'VpcPeeringConnections[*].{ID:VpcPeeringConnectionId,Status:Status.Code}' --output table

.PHONY: clean-vpc-peering
clean-vpc-peering:
	@echo "🗑️  Deleting VPC peering..."
	-@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text 2>/dev/null); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text 2>/dev/null); \
	if [ -n "$$VPC_ID_0" ] && [ -n "$$VPC_ID_1" ]; then \
	  PEERING_ID=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	    --filters "Name=requester-vpc-info.vpc-id,Values=$$VPC_ID_0" \
	              "Name=accepter-vpc-info.vpc-id,Values=$$VPC_ID_1" \
	              "Name=status-code,Values=active,pending-acceptance" \
	    --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text); \
	  if [ "$$PEERING_ID" != "None" ] && [ -n "$$PEERING_ID" ]; then \
	    aws ec2 delete-vpc-peering-connection --region $(AWS_REGION_0) \
	      --vpc-peering-connection-id $$PEERING_ID; \
	    echo "  ✅ Deleted peering $$PEERING_ID"; \
	  else \
	    echo "  No active peering found."; \
	  fi; \
	fi

# ── DNS Chaining ───────────────────────────────────────────────────────────

.PHONY: configure-dns
configure-dns: deploy-dns-lb wait-for-dns-lb apply-coredns-config

.PHONY: deploy-dns-lb
deploy-dns-lb:
	@echo "🌐 Deploying internal DNS load balancers..."
	kubectl --context $(CLUSTER_0) apply -f $(root)/recipes/aws/include/internal-dns-lb.yml
	kubectl --context $(CLUSTER_1) apply -f $(root)/recipes/aws/include/internal-dns-lb.yml

.PHONY: wait-for-dns-lb
wait-for-dns-lb:
	@echo "⏳ Waiting for DNS LB in region 0..."
	@for i in $$(seq 1 60); do \
	  ADDR=$$(kubectl --context $(CLUSTER_0) get svc kube-dns-lb -n kube-system \
	    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	  if [ -n "$$ADDR" ]; then echo "  ✅ Region 0 DNS LB: $$ADDR"; break; fi; \
	  if [ $$i -eq 60 ]; then echo "  ❌ Timeout"; exit 1; fi; \
	  echo "  Waiting... ($$i/60)"; sleep 5; \
	done
	@echo "⏳ Waiting for DNS LB in region 1..."
	@for i in $$(seq 1 60); do \
	  ADDR=$$(kubectl --context $(CLUSTER_1) get svc kube-dns-lb -n kube-system \
	    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	  if [ -n "$$ADDR" ]; then echo "  ✅ Region 1 DNS LB: $$ADDR"; break; fi; \
	  if [ $$i -eq 60 ]; then echo "  ❌ Timeout"; exit 1; fi; \
	  echo "  Waiting... ($$i/60)"; sleep 5; \
	done

.PHONY: apply-coredns-config
apply-coredns-config:
	@echo "🔗 Applying CoreDNS cross-region forwarding..."
	@DNS_LB_0_HOST=$$(kubectl --context $(CLUSTER_0) get svc kube-dns-lb -n kube-system \
	  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null); \
	DNS_LB_0_IP=$$(kubectl --context $(CLUSTER_0) get svc kube-dns-lb -n kube-system \
	  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	DNS_LB_1_HOST=$$(kubectl --context $(CLUSTER_1) get svc kube-dns-lb -n kube-system \
	  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null); \
	DNS_LB_1_IP=$$(kubectl --context $(CLUSTER_1) get svc kube-dns-lb -n kube-system \
	  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null); \
	if [ -n "$$DNS_LB_0_IP" ]; then DNS_LB_0=$$DNS_LB_0_IP; \
	elif [ -n "$$DNS_LB_0_HOST" ]; then DNS_LB_0=$$(host "$$DNS_LB_0_HOST" 2>/dev/null | awk '/has address/ {print $$4; exit}'); \
	fi; \
	if [ -n "$$DNS_LB_1_IP" ]; then DNS_LB_1=$$DNS_LB_1_IP; \
	elif [ -n "$$DNS_LB_1_HOST" ]; then DNS_LB_1=$$(host "$$DNS_LB_1_HOST" 2>/dev/null | awk '/has address/ {print $$4; exit}'); \
	fi; \
	echo "Region 0 DNS LB IP: $$DNS_LB_0"; \
	echo "Region 1 DNS LB IP: $$DNS_LB_1"; \
	if [ -z "$$DNS_LB_0" ] || [ -z "$$DNS_LB_1" ]; then \
	  echo "❌ ERROR: Could not resolve DNS LB IPs."; \
	  echo "   Ensure NLBs are provisioned (make wait-for-dns-lb) and 'host' command works."; \
	  exit 1; \
	fi; \
	echo ""; \
	echo "=== Patching CoreDNS in Cluster 0 ($(CLUSTER_0)) ==="; \
	echo "  Forwarding $(CAMUNDA_NAMESPACE_1).svc.cluster.local → $$DNS_LB_1"; \
	kubectl --context $(CLUSTER_0) -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
	  | sed '/^$(CAMUNDA_NAMESPACE_1)\.svc\.cluster\.local/,/^}/d' > /tmp/corefile0-base.txt; \
	printf '\n$(CAMUNDA_NAMESPACE_1).svc.cluster.local:53 {\n    errors\n    cache 30\n    forward . %s {\n        force_tcp\n    }\n}\n' "$$DNS_LB_1" >> /tmp/corefile0-base.txt; \
	kubectl --context $(CLUSTER_0) -n kube-system create configmap coredns \
	  --from-file=Corefile=/tmp/corefile0-base.txt --dry-run=client -o yaml | \
	  kubectl --context $(CLUSTER_0) -n kube-system apply -f -; \
	echo "  ✅ CoreDNS patched in cluster 0"; \
	echo ""; \
	echo "=== Patching CoreDNS in Cluster 1 ($(CLUSTER_1)) ==="; \
	echo "  Forwarding $(CAMUNDA_NAMESPACE_0).svc.cluster.local → $$DNS_LB_0"; \
	kubectl --context $(CLUSTER_1) -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
	  | sed '/^$(CAMUNDA_NAMESPACE_0)\.svc\.cluster\.local/,/^}/d' > /tmp/corefile1-base.txt; \
	printf '\n$(CAMUNDA_NAMESPACE_0).svc.cluster.local:53 {\n    errors\n    cache 30\n    forward . %s {\n        force_tcp\n    }\n}\n' "$$DNS_LB_0" >> /tmp/corefile1-base.txt; \
	kubectl --context $(CLUSTER_1) -n kube-system create configmap coredns \
	  --from-file=Corefile=/tmp/corefile1-base.txt --dry-run=client -o yaml | \
	  kubectl --context $(CLUSTER_1) -n kube-system apply -f -; \
	echo "  ✅ CoreDNS patched in cluster 1"; \
	echo ""; \
	echo "⏳ Restarting CoreDNS..."; \
	kubectl --context $(CLUSTER_0) -n kube-system rollout restart deployment/coredns; \
	kubectl --context $(CLUSTER_1) -n kube-system rollout restart deployment/coredns; \
	sleep 10; \
	echo "✅ CoreDNS configuration applied to both clusters"

.PHONY: test-dns
test-dns:
	@echo "🧪 Testing DNS chaining between clusters..."
	-kubectl --context $(CLUSTER_0) create namespace $(CAMUNDA_NAMESPACE_0) 2>/dev/null
	-kubectl --context $(CLUSTER_1) create namespace $(CAMUNDA_NAMESPACE_1) 2>/dev/null
	kubectl --context $(CLUSTER_0) -n $(CAMUNDA_NAMESPACE_0) run dns-test --image=busybox:1.36 --restart=Never -- sleep 3600 2>/dev/null || true
	kubectl --context $(CLUSTER_0) -n $(CAMUNDA_NAMESPACE_0) expose pod dns-test --port=80 --name=dns-test 2>/dev/null || true
	kubectl --context $(CLUSTER_1) -n $(CAMUNDA_NAMESPACE_1) run dns-test --image=busybox:1.36 --restart=Never -- sleep 3600 2>/dev/null || true
	kubectl --context $(CLUSTER_1) -n $(CAMUNDA_NAMESPACE_1) expose pod dns-test --port=80 --name=dns-test 2>/dev/null || true
	@echo "⏳ Waiting for pods..."
	kubectl --context $(CLUSTER_0) -n $(CAMUNDA_NAMESPACE_0) wait --for=condition=Ready pod/dns-test --timeout=60s
	kubectl --context $(CLUSTER_1) -n $(CAMUNDA_NAMESPACE_1) wait --for=condition=Ready pod/dns-test --timeout=60s
	@echo ""
	@echo "Region 0 → Region 1:"
	@kubectl --context $(CLUSTER_0) -n $(CAMUNDA_NAMESPACE_0) exec dns-test -- \
	  nslookup dns-test.$(CAMUNDA_NAMESPACE_1).svc.cluster.local && echo "  ✅ DNS OK" || echo "  ❌ DNS FAILED"
	@echo ""
	@echo "Region 1 → Region 0:"
	@kubectl --context $(CLUSTER_1) -n $(CAMUNDA_NAMESPACE_1) exec dns-test -- \
	  nslookup dns-test.$(CAMUNDA_NAMESPACE_0).svc.cluster.local && echo "  ✅ DNS OK" || echo "  ❌ DNS FAILED"

.PHONY: clean-dns-test
clean-dns-test:
	-kubectl --context $(CLUSTER_0) -n $(CAMUNDA_NAMESPACE_0) delete svc dns-test --grace-period=0
	-kubectl --context $(CLUSTER_0) -n $(CAMUNDA_NAMESPACE_0) delete pod dns-test --grace-period=0
	-kubectl --context $(CLUSTER_1) -n $(CAMUNDA_NAMESPACE_1) delete svc dns-test --grace-period=0
	-kubectl --context $(CLUSTER_1) -n $(CAMUNDA_NAMESPACE_1) delete pod dns-test --grace-period=0
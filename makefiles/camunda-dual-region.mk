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

# ── Dual-Region Variables ──────────────────────────────────────────────────
CLUSTER_0 ?=
CLUSTER_1 ?=
CAMUNDA_NAMESPACE_0 ?= camunda-region0
CAMUNDA_NAMESPACE_1 ?= camunda-region1

# Dual-region cluster sizing (override in config.mk)
# CAMUNDA_CLUSTER_SIZE_DR is the TOTAL across both regions (chart divides by regions for replicas)
CAMUNDA_CLUSTER_SIZE_DR ?= 4
CAMUNDA_REPLICATION_FACTOR_DR ?= 4
CAMUNDA_PARTITION_COUNT_DR ?= 4
BROKERS_PER_REGION := $(shell echo $$(( $(CAMUNDA_CLUSTER_SIZE_DR) / 2 )))

# Generate Zeebe initial contact points for all brokers across both regions
define generate_contact_points
$(shell \
  points=""; sep=""; \
  for i in $$(seq 0 $$(( $(BROKERS_PER_REGION) - 1 )) ); do \
    points="$${points}$${sep}$(CAMUNDA_RELEASE_NAME)-zeebe-$${i}.$(CAMUNDA_RELEASE_NAME)-zeebe.$(CAMUNDA_NAMESPACE_0).svc.cluster.local:26502"; \
    sep=","; \
    points="$${points}$${sep}$(CAMUNDA_RELEASE_NAME)-zeebe-$${i}.$(CAMUNDA_RELEASE_NAME)-zeebe.$(CAMUNDA_NAMESPACE_1).svc.cluster.local:26502"; \
  done; \
  echo "$$points" \
)
endef

ZEEBE_INITIAL_CONTACT_POINTS = $(call generate_contact_points)

# ── Deploy targets ─────────────────────────────────────────────────────────
# Each target: switches context → copies region values → calls existing targets

.PHONY: deploy-region0
deploy-region0: camunda-values-region0.yaml
	@echo "🚀 Deploying Camunda to region 0 ($(CLUSTER_0) / $(CAMUNDA_NAMESPACE_0))..."
	kubectl config use-context $(CLUSTER_0)
	cp camunda-values-region0.yaml camunda-values.yaml
	$(MAKE) create-camunda-credentials camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_0)

.PHONY: deploy-region1
deploy-region1: camunda-values-region1.yaml
	@echo "🚀 Deploying Camunda to region 1 ($(CLUSTER_1) / $(CAMUNDA_NAMESPACE_1))..."
	kubectl config use-context $(CLUSTER_1)
	cp camunda-values-region1.yaml camunda-values.yaml
	$(MAKE) create-camunda-credentials camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_1)

.PHONY: deploy-dual-region
deploy-dual-region: deploy-region0 deploy-region1

# ── Region-specific values generation ──────────────────────────────────────
# Generates a dual-region base values file using CAMUNDA_HELM_VALUES_DR,
# then substitutes <REGION_ID> for each region.

camunda-values-dr-base.yaml: delete-camunda-values
	@echo "📝 Generating dual-region base values..."
	yq eval-all '. as $$item ireduce ({}; . * $$item)' $(CAMUNDA_HELM_VALUES_DR) | \
	sed "s|<CAMUNDA_VERSION>|$(CAMUNDA_VERSION)|g; \
	     s|<CAMUNDA_CLUSTER_SIZE>|$(CAMUNDA_CLUSTER_SIZE_DR)|g; \
	     s|<CAMUNDA_REPLICATION_FACTOR>|$(CAMUNDA_REPLICATION_FACTOR_DR)|g; \
	     s|<CAMUNDA_PARTITION_COUNT>|$(CAMUNDA_PARTITION_COUNT_DR)|g; \
	     s|<CAMUNDA_RELEASE_NAME>|$(CAMUNDA_RELEASE_NAME)|g; \
	     s|<POSTGRES_HOST>|$(POSTGRES_HOST)|g; \
	     s|<POSTGRES_CAMUNDA_DB>|$(POSTGRES_CAMUNDA_DB)|g; \
	     s|<POSTGRES_CAMUNDA_USERNAME>|$(POSTGRES_CAMUNDA_USERNAME)|g; \
	     s|<ZEEBE_INITIAL_CONTACT_POINTS>|$(ZEEBE_INITIAL_CONTACT_POINTS)|g; \
	     s|<DEFAULT_PASSWORD>|$(DEFAULT_PASSWORD)|g;" \
	     > camunda-values-dr-base.yaml

camunda-values-region0.yaml: camunda-values-dr-base.yaml
	@echo "📝 Generating region 0 values..."
	sed 's|<REGION_ID>|0|g' camunda-values-dr-base.yaml > camunda-values-region0.yaml

camunda-values-region1.yaml: camunda-values-dr-base.yaml
	@echo "📝 Generating region 1 values..."
	sed 's|<REGION_ID>|1|g' camunda-values-dr-base.yaml > camunda-values-region1.yaml

# ── Clean targets ──────────────────────────────────────────────────────────

.PHONY: clean-region0
clean-region0:
	@echo "🧹 Removing Camunda from region 0..."
	kubectl config use-context $(CLUSTER_0)
	$(MAKE) clean-camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_0)

.PHONY: clean-region1
clean-region1:
	@echo "🧹 Removing Camunda from region 1..."
	kubectl config use-context $(CLUSTER_1)
	$(MAKE) clean-camunda CAMUNDA_NAMESPACE=$(CAMUNDA_NAMESPACE_1)

.PHONY: clean-dual-region
clean-dual-region: clean-region0 clean-region1

.PHONY: clean-dr-generated
clean-dr-generated:
	-rm -f camunda-values-dr-base.yaml camunda-values-region0.yaml camunda-values-region1.yaml

# ── Verification ───────────────────────────────────────────────────────────

.PHONY: pods-region0
pods-region0:
	kubectl --context $(CLUSTER_0) get pods -n $(CAMUNDA_NAMESPACE_0)

.PHONY: pods-region1
pods-region1:
	kubectl --context $(CLUSTER_1) get pods -n $(CAMUNDA_NAMESPACE_1)

# ── Context switching ─────────────────────────────────────────────────────

.PHONY: use-region0
use-region0:
	kubectl config use-context $(CLUSTER_0)

.PHONY: use-region1
use-region1:
	kubectl config use-context $(CLUSTER_1)

# ── Verification ──────────────────────────────────────────────────────────

.PHONY: topology
topology: use-region0
	@echo "Checking Zeebe topology via region 0..."
	kubectl -n $(CAMUNDA_NAMESPACE_0) \
	  port-forward svc/$(CAMUNDA_RELEASE_NAME)-zeebe-gateway 8888:8080 &
	@sleep 3
	@curl -sf -u demo:demo http://localhost:8888/v2/topology | jq . || \
	  echo "⚠️  Could not reach Zeebe gateway."
	@kill %1 2>/dev/null || true

.PHONY: port-orchestration-region0
port-orchestration-region0: use-region0
	@echo "Port-forwarding orchestration region 0 (8080 → 8080). Press Ctrl+C to stop."
	kubectl -n $(CAMUNDA_NAMESPACE_0) \
	  port-forward svc/$(CAMUNDA_RELEASE_NAME)-zeebe-gateway 8080:8080

.PHONY: port-orchestration-region1
port-orchestration-region1: use-region1
	@echo "Port-forwarding orchestration region 1 (8080 → 8080). Press Ctrl+C to stop."
	kubectl -n $(CAMUNDA_NAMESPACE_1) \
	  port-forward svc/$(CAMUNDA_RELEASE_NAME)-zeebe-gateway 8080:8080

# ── Failure Simulation ────────────────────────────────────────────────────
# Simulates a network partition by removing VPC peering routes.
# Brokers stay running but cannot communicate across regions.
# Zeebe loses quorum → processing stops.
# Restore with: make restore-partition

.PHONY: simulate-partition
simulate-partition:
	@echo "🔥 Simulating network partition between regions..."
	@echo ""
	@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_CIDR_0=$$(aws ec2 describe-vpcs --region $(AWS_REGION_0) \
	  --vpc-ids $$VPC_ID_0 --query 'Vpcs[0].CidrBlock' --output text); \
	VPC_CIDR_1=$$(aws ec2 describe-vpcs --region $(AWS_REGION_1) \
	  --vpc-ids $$VPC_ID_1 --query 'Vpcs[0].CidrBlock' --output text); \
	PEERING_ID=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	  --filters "Name=requester-vpc-info.vpc-id,Values=$$VPC_ID_0" \
	            "Name=accepter-vpc-info.vpc-id,Values=$$VPC_ID_1" \
	            "Name=status-code,Values=active" \
	  --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text); \
	if [ "$$PEERING_ID" = "None" ] || [ -z "$$PEERING_ID" ]; then \
	  echo "❌ No active peering found."; exit 1; \
	fi; \
	echo "  Peering: $$PEERING_ID"; \
	echo ""; \
	echo "  --- Removing routes in Region 0 ($$VPC_CIDR_1 via $$PEERING_ID) ---"; \
	for RT in $$(aws ec2 describe-route-tables --region $(AWS_REGION_0) \
	    --filters "Name=vpc-id,Values=$$VPC_ID_0" \
	    --query 'RouteTables[*].RouteTableId' --output text); do \
	  aws ec2 delete-route --region $(AWS_REGION_0) \
	    --route-table-id $$RT \
	    --destination-cidr-block $$VPC_CIDR_1 2>/dev/null && \
	    echo "    $$RT: ✅ route removed" || echo "    $$RT: ⚠️  no route found"; \
	done; \
	echo ""; \
	echo "  --- Removing routes in Region 1 ($$VPC_CIDR_0 via $$PEERING_ID) ---"; \
	for RT in $$(aws ec2 describe-route-tables --region $(AWS_REGION_1) \
	    --filters "Name=vpc-id,Values=$$VPC_ID_1" \
	    --query 'RouteTables[*].RouteTableId' --output text); do \
	  aws ec2 delete-route --region $(AWS_REGION_1) \
	    --route-table-id $$RT \
	    --destination-cidr-block $$VPC_CIDR_0 2>/dev/null && \
	    echo "    $$RT: ✅ route removed" || echo "    $$RT: ⚠️  no route found"; \
	done; \
	echo ""; \
	echo "🔥 Network partition active. Regions cannot communicate."; \
	echo "   Zeebe will lose quorum and stop processing."; \
	echo "   To restore: make restore-partition"

.PHONY: restore-partition
restore-partition:
	@echo "🔧 Restoring network connectivity between regions..."
	@echo ""
	@VPC_ID_0=$$(aws eks describe-cluster --region $(AWS_REGION_0) --name $(CLUSTER_0) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_ID_1=$$(aws eks describe-cluster --region $(AWS_REGION_1) --name $(CLUSTER_1) \
	  --query 'cluster.resourcesVpcConfig.vpcId' --output text); \
	VPC_CIDR_0=$$(aws ec2 describe-vpcs --region $(AWS_REGION_0) \
	  --vpc-ids $$VPC_ID_0 --query 'Vpcs[0].CidrBlock' --output text); \
	VPC_CIDR_1=$$(aws ec2 describe-vpcs --region $(AWS_REGION_1) \
	  --vpc-ids $$VPC_ID_1 --query 'Vpcs[0].CidrBlock' --output text); \
	PEERING_ID=$$(aws ec2 describe-vpc-peering-connections --region $(AWS_REGION_0) \
	  --filters "Name=requester-vpc-info.vpc-id,Values=$$VPC_ID_0" \
	            "Name=accepter-vpc-info.vpc-id,Values=$$VPC_ID_1" \
	            "Name=status-code,Values=active" \
	  --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' --output text); \
	if [ "$$PEERING_ID" = "None" ] || [ -z "$$PEERING_ID" ]; then \
	  echo "❌ No active peering found. May need full reconfiguration: make configure-vpc-peering"; exit 1; \
	fi; \
	echo "  Peering: $$PEERING_ID"; \
	echo ""; \
	echo "  --- Restoring routes in Region 0 ($$VPC_CIDR_1 → $$PEERING_ID) ---"; \
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
	echo "  --- Restoring routes in Region 1 ($$VPC_CIDR_0 → $$PEERING_ID) ---"; \
	for RT in $$(aws ec2 describe-route-tables --region $(AWS_REGION_1) \
	    --filters "Name=vpc-id,Values=$$VPC_ID_1" \
	    --query 'RouteTables[*].RouteTableId' --output text); do \
	  aws ec2 create-route --region $(AWS_REGION_1) \
	    --route-table-id $$RT \
	    --destination-cidr-block $$VPC_CIDR_0 \
	    --vpc-peering-connection-id $$PEERING_ID > /dev/null 2>&1 && \
	    echo "    $$RT: ✅ route added" || echo "    $$RT: ⚠️  route exists"; \
	done; \
	echo ""; \
	echo "✅ Network connectivity restored."; \
	echo "   Zeebe should automatically recover quorum."; \
	echo "   Verify with: make topology"
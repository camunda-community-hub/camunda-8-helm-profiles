# Provision two AWS EKS clusters with VPC peering and DNS chaining
# for dual-region Camunda deployments.
#
# Run 'make help' to see available targets.

# ── Root directory resolution ───────────────────────────────────────────────
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../..
else
    root ?= $(shell pwd)/../../..
endif

# ── Configuration ───────────────────────────────────────────────────────────
-include $(root)/config.mk
include ./config.mk

# ── Primary targets ─────────────────────────────────────────────────────────

.PHONY: all
all: create-cluster-region0 create-cluster-region1 configure-vpc-peering configure-dns
	@echo ""
	@echo "✅ Infrastructure ready. To deploy Camunda:"
	@echo "   cd ../../camunda/8.9/orchestration-internal-postgres/"
	@echo "   make deploy-dual-region CLUSTER_0=$(CLUSTER_0) CLUSTER_1=$(CLUSTER_1)"

.PHONY: clean
clean: clean-vpc-peering clean-cluster-region0 clean-cluster-region1

.PHONY: help
help:
	@echo ""
	@echo "Camunda 8 Dual-Region on AWS EKS"
	@echo "═══════════════════════════════════"
	@echo ""
	@echo "  ── Cluster Management ──────────────────────────────────────"
	@echo "  create-cluster-region0   Create EKS cluster in $(AWS_REGION_0)"
	@echo "  create-cluster-region1   Create EKS cluster in $(AWS_REGION_1)"
	@echo "  clean-cluster-region0    Delete EKS cluster in region 0"
	@echo "  clean-cluster-region1    Delete EKS cluster in region 1"
	@echo ""
	@echo "  ── VPC Peering ─────────────────────────────────────────────"
	@echo "  configure-vpc-peering    Full VPC peering setup"
	@echo "  vpc-peering-status       Show current peering status"
	@echo "  clean-vpc-peering        Delete VPC peering"
	@echo ""
	@echo "  ── DNS Chaining ────────────────────────────────────────────"
	@echo "  configure-dns            Full DNS setup (LB + CoreDNS)"
	@echo "  test-dns                 Test cross-region DNS resolution"
	@echo "  clean-dns-test           Remove DNS test resources"
	@echo ""
	@echo "  ── Workflow ────────────────────────────────────────────────"
	@echo "  1. make create-cluster-region0  (terminal 1)"
	@echo "     make create-cluster-region1  (terminal 2)"
	@echo "  2. make configure-vpc-peering"
	@echo "  3. make configure-dns"
	@echo "  4. make test-dns"
	@echo "  5. cd ../../camunda/8.9/orchestration-internal-postgres/"
	@echo "  6. make deploy-dual-region"
	@echo ""

# ── Include shared makefiles ───────────────────────────────────────────────
include $(root)/makefiles/aws-eks.mk
include $(root)/makefiles/aws-eks-dual-region.mk
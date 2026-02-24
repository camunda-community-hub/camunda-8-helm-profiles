# Determine the root directory
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../..
else
    root ?= $(shell pwd)/../../../..
endif

# Create a config.mk file in the root directory of this project to override defaults included below
-include $(root)/config.mk

# Theses are the default values used by this recipe
include ./config.mk


.PHONY: all
all: camunda-values.yaml create-camunda-credentials camunda

.PHONY: clean
clean: clean-camunda

.PHONY: help
help:
	@echo ""
	@echo "Camunda 8.9 — Orchestration with Internal PostgreSQL"
	@echo "═════════════════════════════════════════════════════"
	@echo ""
	@echo "  ── Single-Region ───────────────────────────────────────────"
	@echo "  all                      Deploy Camunda (generate values + credentials + install)"
	@echo "  clean                    Uninstall Camunda (helm uninstall + PVCs + namespace)"
	@echo ""
	@echo "  ── Dual-Region ─────────────────────────────────────────────"
	@echo "  deploy-region0           Deploy Camunda to region 0"
	@echo "  deploy-region1           Deploy Camunda to region 1"
	@echo "  deploy-dual-region       Deploy to both regions sequentially"
	@echo "  clean-region0            Uninstall Camunda from region 0"
	@echo "  clean-region1            Uninstall Camunda from region 1"
	@echo "  clean-dual-region        Uninstall from both regions"
	@echo "  clean-dr-generated       Remove generated dual-region values files"
	@echo ""
	@echo "  ── Context & Port-Forwarding ───────────────────────────────"
	@echo "  use-region0              Switch kubectl context to region 0"
	@echo "  use-region1              Switch kubectl context to region 1"
	@echo "  port-orchestration       Port-forward REST API (8080 → 8080)"
	@echo "  port-orchestration-region0  Port-forward REST API for region 0"
	@echo "  port-orchestration-region1  Port-forward REST API for region 1"
	@echo "  port-zeebe               Port-forward gRPC (26500 → 26500)"
	@echo ""
	@echo "  ── Verification & Testing ──────────────────────────────────"
	@echo "  topology                 Check Zeebe cluster topology (region 0)"
	@echo "  pods-region0             List pods in region 0"
	@echo "  pods-region1             List pods in region 1"
	@echo "  deploy-bpmn              Deploy BPMN model (default: hello_user_task.bpmn)"
	@echo "  create-instance          Create a process instance (default: Process_08p1wio)"
	@echo "  get-tasks                Search for user tasks"
	@echo "  get-definitions          List deployed process definitions"
	@echo "  get-instances            List process instances"
	@echo "  test-bpmn                All-in-one: deploy + instance + get tasks"
	@echo ""
	@echo "  ── Single-Region Workflow ──────────────────────────────────"
	@echo "  1. Provision cluster:    cd ../../aws/eks/ && make"
	@echo "  2. Deploy Camunda:       make"
	@echo "  3. Port-forward:         make port-orchestration"
	@echo "  4. Test (new terminal):  make test-bpmn"
	@echo ""
	@echo "  ── Dual-Region Workflow ────────────────────────────────────"
	@echo "  1. Provision clusters:   cd ../../aws/eks-dual-region/ && make"
	@echo "  2. Set cluster contexts: export CLUSTER_0=... CLUSTER_1=..."
	@echo "  3. Deploy both regions:  make deploy-dual-region"
	@echo "  4. Verify topology:      make topology"
	@echo "  5. Port-forward:         make port-orchestration-region0"
	@echo "  6. Test (new terminal):  make test-bpmn"
	@echo ""

include $(root)/makefiles/camunda.mk
include $(root)/makefiles/camunda-dual-region.mk
include $(root)/makefiles/camunda-test.mk
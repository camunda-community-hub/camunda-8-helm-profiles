# ════════════════════════════════════════════════════════════════════════════
# CAMUNDA TEST TARGETS
# ════════════════════════════════════════════════════════════════════════════
#
# REST API targets for testing Camunda deployments.
# Uses the v2 REST API with basic auth (demo:demo).
#
# Requires port-forwarding to be running:
#   make port-orchestration CAMUNDA_NAMESPACE=<namespace>
#   or: make port-orchestration-region0
#
# Usage:
#   make deploy-bpmn BPMN_FILE=hello_user_task.bpmn
#   make create-instance PROCESS_ID=Process_08p1wio
#   make get-tasks
#   make test-bpmn    # all-in-one: deploy + instance + tasks

# ── Variables ──────────────────────────────────────────────────────────────
CAMUNDA_API_URL ?= http://localhost:8080
CAMUNDA_AUTH ?= demo:demo
BPMN_DIR ?= $(root)/bpmn
BPMN_FILE ?= hello_user_task.bpmn
PROCESS_ID ?= Process_08p1wio

# ── Deploy BPMN ───────────────────────────────────────────────────────────

.PHONY: deploy-bpmn
deploy-bpmn:
	@echo "📦 Deploying $(BPMN_FILE)..."
	@RESPONSE=$$(curl -s -w "\n%{http_code}" -u $(CAMUNDA_AUTH) \
	  -F "resources=@$(BPMN_DIR)/$(BPMN_FILE)" \
	  $(CAMUNDA_API_URL)/v2/deployments); \
	HTTP_CODE=$$(echo "$$RESPONSE" | tail -1); \
	BODY=$$(echo "$$RESPONSE" | sed '$$d'); \
	if [ "$$HTTP_CODE" -ge 200 ] && [ "$$HTTP_CODE" -lt 300 ]; then \
	  echo "✅ Deployed successfully (HTTP $$HTTP_CODE)"; \
	  echo "$$BODY" | jq .; \
	else \
	  echo "❌ Deploy failed (HTTP $$HTTP_CODE)"; \
	  echo "$$BODY" | jq . 2>/dev/null || echo "$$BODY"; \
	fi

# ── Process Instances ─────────────────────────────────────────────────────

.PHONY: create-instance
create-instance:
	@echo "🚀 Creating process instance for $(PROCESS_ID)..."
	@RESPONSE=$$(curl -s -w "\n%{http_code}" -u $(CAMUNDA_AUTH) \
	  -H "Content-Type: application/json" \
	  -d '{"processDefinitionId": "$(PROCESS_ID)"}' \
	  $(CAMUNDA_API_URL)/v2/process-instances); \
	HTTP_CODE=$$(echo "$$RESPONSE" | tail -1); \
	BODY=$$(echo "$$RESPONSE" | sed '$$d'); \
	if [ "$$HTTP_CODE" -ge 200 ] && [ "$$HTTP_CODE" -lt 300 ]; then \
	  echo "✅ Instance created (HTTP $$HTTP_CODE)"; \
	  echo "$$BODY" | jq .; \
	else \
	  echo "❌ Failed to create instance (HTTP $$HTTP_CODE)"; \
	  echo "$$BODY" | jq . 2>/dev/null || echo "$$BODY"; \
	fi

.PHONY: get-instances
get-instances:
	@echo "📋 Process instances:"
	@curl -s -u $(CAMUNDA_AUTH) \
	  -H "Content-Type: application/json" \
	  -d '{}' \
	  $(CAMUNDA_API_URL)/v2/process-instances/search | jq . 2>/dev/null || \
	  echo "❌ Failed to query instances."

# ── User Tasks ────────────────────────────────────────────────────────────

.PHONY: get-tasks
get-tasks:
	@echo "📋 User tasks:"
	@curl -s -u $(CAMUNDA_AUTH) \
	  -H "Content-Type: application/json" \
	  -d '{}' \
	  $(CAMUNDA_API_URL)/v2/user-tasks/search | jq . 2>/dev/null || \
	  echo "❌ Failed to query tasks."

# ── Process Definitions ───────────────────────────────────────────────────

.PHONY: get-definitions
get-definitions:
	@echo "📋 Process definitions:"
	@curl -s -u $(CAMUNDA_AUTH) \
	  -H "Content-Type: application/json" \
	  -d '{}' \
	  $(CAMUNDA_API_URL)/v2/process-definitions/search | jq . 2>/dev/null || \
	  echo "❌ Failed to query definitions."

# ── All-in-one test ──────────────────────────────────────────────────────

.PHONY: test-bpmn
test-bpmn: deploy-bpmn
	@sleep 2
	@$(MAKE) create-instance
	@sleep 3
	@$(MAKE) get-tasks
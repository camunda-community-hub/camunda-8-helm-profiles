# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT)
	root ?= $(CURDIR)/..
else
	root ?= $(shell pwd)/..
endif

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

chartValues ?= $(root)/high-available-webapps/camunda-values.yaml
# Number of replicas for webapps
replicas ?= 3


.PHONY: all
all: camunda await-zeebe scale-operate scale-tasklist scale-optimize await-identity scale-identity

.PHONY: clean
clean: clean-operate clean-tasklist clean-optimize clean-camunda

.PHONY: scale-operate
scale-operate:
	kubectl get deployment $(release)-operate -n $(namespace) -o yaml > operate_template.yaml
	yq eval 'del(.status, .metadata, .spec.template.metadata.annotations, .spec.template.metadata.creationTimestamp,  .spec.selector)' -i operate_template.yaml
	yq eval '.metadata.name = "operate-webapp" | .spec.selector.matchLabels.webapp = "operate-webapp" | .spec.template.metadata.labels.webapp = "operate-webapp" | .spec.replicas = $(replicas)' -i operate_template.yaml
	yq eval '.spec.template.spec.containers[0].env += [{"name": "CAMUNDA_OPERATE_IMPORTERENABLED", "value": "FALSE"}, {"name": "CAMUNDA_OPERATE_ARCHIVERENABLED", "value": "FALSE"}]' operate_template.yaml -i
	kubectl apply -f operate_template.yaml
	rm operate_template.yaml

.PHONY: scale-tasklist
scale-tasklist:
	kubectl get deployment $(release)-tasklist -n $(namespace) -o yaml > tasklist_template.yaml
	yq eval 'del(.status, .metadata, .spec.template.metadata.annotations, .spec.template.metadata.creationTimestamp,  .spec.selector)' -i tasklist_template.yaml
	yq eval '.metadata.name = "tasklist-webapp" | .spec.selector.matchLabels.webapp = "tasklist-webapp" | .spec.template.metadata.labels.webapp = "tasklist-webapp" | .spec.replicas = $(replicas)' -i tasklist_template.yaml
	yq eval '.spec.template.spec.containers[0].env += [{"name": "CAMUNDA_TASKLIST_IMPORTERENABLED", "value": "FALSE"}, {"name": "CAMUNDA_TASKLIST_ARCHIVERENABLED", "value": "FALSE"}]' tasklist_template.yaml -i
	kubectl apply -f tasklist_template.yaml
	rm tasklist_template.yaml

.PHONY: scale-optimize
scale-optimize:
	kubectl get deployment $(release)-optimize -n $(namespace) -o yaml > optimize_template.yaml
	yq eval 'del(.status, .metadata, .spec.template.metadata.annotations, .spec.template.metadata.creationTimestamp,  .spec.selector)' -i optimize_template.yaml
	yq eval '.metadata.name = "optimize-webapp" | .spec.selector.matchLabels.webapp = "optimize-webapp" | .spec.template.metadata.labels.webapp = "optimize-webapp" | .spec.replicas = $(replicas)' -i optimize_template.yaml
	yq eval 'del(.spec.template.spec.containers[0].env[] | select(.name == "CAMUNDA_OPTIMIZE_ZEEBE_ENABLED"))' optimize_template.yaml -i
	yq eval '.spec.template.spec.containers[0].env += [{"name": "CAMUNDA_OPTIMIZE_ZEEBE_ENABLED", "value": "FALSE"}]' optimize_template.yaml -i
	yq eval 'del(.spec.template.spec.initContainers)' optimize_template.yaml -i
	kubectl apply -f optimize_template.yaml
	rm optimize_template.yaml

.PHONY: scale-identity
scale-identity:
	kubectl scale --replicas=$(replicas) deployment/$(release)-identity

.PHONY: await-identity
await-identity:
	kubectl rollout status deployment/$(release)-identity -n $(namespace) --watch --timeout=900s

.PHONY: clean-operate
clean-operate:
	kubectl delete deployment operate-webapp -n $(namespace)

.PHONY: clean-tasklist
clean-tasklist:
	kubectl delete deployment tasklist-webapp -n $(namespace)

.PHONY: clean-optimize
clean-optimize:
	kubectl delete deployment optimize-webapp -n $(namespace)

include $(root)/include/camunda.mk
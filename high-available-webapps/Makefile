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

.PHONY: remove-operate-from-ingress
remove-operate-from-ingress:
	kubectl get ingress $(release)-camunda-platform -n $(namespace) -o yaml > ingress-camunda-platform.yaml
	yq eval 'del(.spec.rules[0].http.paths[] | select(.backend.service.name == "camunda-operate") )' -i ingress-camunda-platform.yaml
	kubectl apply -f ingress-camunda-platform.yaml -n $(namespace)
	rm ingress-camunda-platform.yaml

operate-ingress.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/high-available-webapps/operate-ingress.tpl.yaml > ./operate-ingress.yaml;

.PHONY: create-operate-ingress
create-operate-ingress: remove-operate-from-ingress operate-ingress.yaml
	kubectl apply -f ./operate-ingress.yaml -n $(namespace)
	rm ./operate-ingress.yaml

.PHONY: scale-operate-webapp-yaml
scale-operate-webapp-yaml:
	kubectl get deployment $(release)-operate -n $(namespace) -o yaml > operate_template.yaml
	yq eval 'del(.status, .metadata, .spec.template.metadata.annotations, .spec.template.metadata.creationTimestamp,  .spec.selector)' -i operate_template.yaml
	yq eval '.metadata.name = "operate-webapp" | .spec.selector.matchLabels.webapp = "operate-webapp" | .spec.template.metadata.labels.webapp = "operate-webapp" | .spec.replicas = $(replicas)' -i operate_template.yaml
	yq eval '.spec.template.spec.containers[0].env += [{"name": "CAMUNDA_OPERATE_WEBAPPENABLED", "value": "FALSE"}, {"name": "CAMUNDA_OPERATE_IMPORTERENABLED", "value": "FALSE"}, {"name": "CAMUNDA_OPERATE_ARCHIVERENABLED", "value": "FALSE"}]' operate_template.yaml -i

.PHONY: scale-operate-webapp
scale-operate-webapp: scale-operate-webapp-yaml
	kubectl apply -f operate_template.yaml
	rm operate_template.yaml

.PHONY: scale-operate-importer0-yaml
scale-operate-importer0-yaml:
	kubectl get deployment operate-webapp -n $(namespace) -o yaml > operate_template-import0.yaml
	yq eval 'del(.status, .metadata, .spec.template.metadata.annotations, .spec.template.metadata.creationTimestamp,  .spec.selector)' -i operate_template-import0.yaml
	yq eval '.metadata.name = "operate-import0" | .spec.selector.matchLabels.webapp = "operate-import0" | .spec.template.metadata.labels.webapp = "operate-import0" | .spec.replicas = 1' -i operate_template-import0.yaml
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_WEBAPPENABLED") )' operate_template-import0.yaml -i
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_IMPORTERENABLED") )' operate_template-import0.yaml -i
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_ARCHIVERENABLED") )' operate_template-import0.yaml -i
	yq eval '.spec.template.spec.containers[0].env += [{"name": "CAMUNDA_OPERATE_WEBAPPENABLED", "value": "FALSE"}, {"name": "CAMUNDA_OPERATE_IMPORTERENABLED", "value": "TRUE"}, {"name": "CAMUNDA_OPERATE_ARCHIVERENABLED", "value": "TRUE"}, {"name": "CAMUNDA_OPERATE_CLUSTERNODE_NODECOUNT", "value": "3"}, {"name": "CAMUNDA_OPERATE_CLUSTERNODE_CURRENTNODEID", "value": "0"} ]' operate_template-import0.yaml -i

.PHONY: scale-operate-importer0
scale-operate-importer0: scale-operate-importer0-yaml
	-kubectl delete deployment $(release)-operate -n $(namespace)
	kubectl apply -f operate_template-import0.yaml
	rm operate_template-import0.yaml

.PHONY: scale-operate-importer1-yaml
scale-operate-importer1-yaml:
	kubectl get deployment operate-webapp -n $(namespace) -o yaml > operate_template-import1.yaml
	yq eval 'del(.status, .metadata, .spec.template.metadata.annotations, .spec.template.metadata.creationTimestamp,  .spec.selector)' -i operate_template-import1.yaml
	yq eval '.metadata.name = "operate-import1" | .spec.selector.matchLabels.webapp = "operate-import1" | .spec.template.metadata.labels.webapp = "operate-import1" | .spec.replicas = 1' -i operate_template-import1.yaml
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_WEBAPPENABLED") )' operate_template-import1.yaml -i
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_IMPORTERENABLED") )' operate_template-import1.yaml -i
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_ARCHIVERENABLED") )' operate_template-import1.yaml -i
	yq eval '.spec.template.spec.containers[0].env += [{"name": "CAMUNDA_OPERATE_WEBAPPENABLED", "value": "FALSE"}, {"name": "CAMUNDA_OPERATE_IMPORTERENABLED", "value": "TRUE"}, {"name": "CAMUNDA_OPERATE_ARCHIVERENABLED", "value": "TRUE"}, {"name": "CAMUNDA_OPERATE_CLUSTERNODE_NODECOUNT", "value": "3"}, {"name": "CAMUNDA_OPERATE_CLUSTERNODE_CURRENTNODEID", "value": "1"} ]' operate_template-import1.yaml -i

.PHONY: scale-operate-importer1
scale-operate-importer1: scale-operate-importer1-yaml
	-kubectl delete deployment $(release)-operate -n $(namespace)
	kubectl apply -f operate_template-import1.yaml
	rm operate_template-import1.yaml

.PHONY: scale-operate-importer2-yaml
scale-operate-importer2-yaml:
	kubectl get deployment operate-webapp -n $(namespace) -o yaml > operate_template-import2.yaml
	yq eval 'del(.status, .metadata, .spec.template.metadata.annotations, .spec.template.metadata.creationTimestamp,  .spec.selector)' -i operate_template-import2.yaml
	yq eval '.metadata.name = "operate-import2" | .spec.selector.matchLabels.webapp = "operate-import2" | .spec.template.metadata.labels.webapp = "operate-import2" | .spec.replicas = 1' -i operate_template-import2.yaml
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_WEBAPPENABLED") )' operate_template-import2.yaml -i
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_IMPORTERENABLED") )' operate_template-import2.yaml -i
	yq eval 'del (.spec.template.spec.containers[0].env.[] | select(.name == "CAMUNDA_OPERATE_ARCHIVERENABLED") )' operate_template-import2.yaml -i
	yq eval '.spec.template.spec.containers[0].env += [{"name": "CAMUNDA_OPERATE_WEBAPPENABLED", "value": "FALSE"}, {"name": "CAMUNDA_OPERATE_IMPORTERENABLED", "value": "TRUE"}, {"name": "CAMUNDA_OPERATE_ARCHIVERENABLED", "value": "TRUE"}, {"name": "CAMUNDA_OPERATE_CLUSTERNODE_NODECOUNT", "value": "3"}, {"name": "CAMUNDA_OPERATE_CLUSTERNODE_CURRENTNODEID", "value": "2"} ]' operate_template-import2.yaml -i

.PHONY: scale-operate-importer2
scale-operate-importer2: scale-operate-importer2-yaml
	kubectl apply -f operate_template-import2.yaml
	rm operate_template-import2.yaml

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
include $(root)/include/ingress-nginx.mk
.PHONY: camunda # download Helm chart, create namespace, install Camunda Platform
camunda: camunda-chart namespace install-camunda

.PHONY: install-camunda # install Camunda Platform
install-camunda:
	@echo "Installing Camunda Platform using camunda-values.yaml"
	helm upgrade --install --namespace $(CAMUNDA_NAMESPACE) $(CAMUNDA_RELEASE_NAME) $(CAMUNDA_CHART) \
	  -f ./camunda-values.yaml --version $(CAMUNDA_HELM_CHART_VERSION) --skip-crds

.PHONY: dry-run-camunda # perform a dry-run installation of Camunda Platform
dry-run-camunda:
	@echo "Performing a dry-run installation of $(CAMUNDA_CHART) using chartValues: ./camunda-values.yaml"
	helm upgrade --install --namespace $(CAMUNDA_NAMESPACE) $(CAMUNDA_RELEASE_NAME) $(CAMUNDA_CHART) \
	 -f ./camunda-values.yaml --version $(CAMUNDA_HELM_CHART_VERSION) --skip-crds --dry-run --debug

.PHONY: camunda-versions # list Helm Chart versions + Camunda Platform versions
camunda-versions:
	helm search repo camunda -l

.PHONY: camunda-chart # download the Camunda Platform Helm chart
camunda-chart:
	helm repo add camunda https://helm.camunda.io
	helm repo update camunda
	helm search repo $(CAMUNDA_CHART)

.PHONY: camunda-chart-infos # store Camunda Platform Helm chart version, its values, and readme
camunda-chart-infos:
	helm search repo $(CAMUNDA_CHART) --output yaml > helm-chart-version.yaml
	helm show values $(CAMUNDA_CHART) > helm-chart-default-values.yaml
	helm show readme $(CAMUNDA_CHART) > helm-chart-readme.md

.PHONY: namespace # create the Kubernetes namespace
namespace:
	-kubectl create namespace $(CAMUNDA_NAMESPACE)
	-kubectl config set-context --current --namespace=$(CAMUNDA_NAMESPACE)

.PHONY: template # generate templates from the Camunda Helm Chart, useful to make some more specific changes which are not doable by the values file.
template: camunda-chart
	helm template $(CAMUNDA_RELEASE_NAME) $(CAMUNDA_CHART) \
	--values ./camunda-values.yaml --version $(CAMUNDA_HELM_CHART_VERSION) --skip-crds \
	--output-dir helm-templates-$(CAMUNDA_RELEASE_NAME)
	@echo "To apply the templates use: kubectl apply -f helm-templates-$(CAMUNDA_RELEASE_NAME) --recursive -n $(CAMUNDA_NAMESPACE)"

.PHONY: clean-template # delete the gerenated Helm templates
clean-template:
	rm -r helm-templates-$(release)

.PHONY: update-camunda
update-camunda: camunda-chart camunda-values.yaml create-camunda-credentials
	helm upgrade --namespace $(CAMUNDA_NAMESPACE) $(CAMUNDA_RELEASE_NAME) $(CAMUNDA_CHART) \
	-f ./camunda-values.yaml --version $(CAMUNDA_HELM_CHART_VERSION)

.PHONY: delete-camunda-values
delete-camunda-values:
	-rm -f ./camunda-values.yaml

.PHONY: uninstall-camunda
uninstall-camunda:
	-helm --namespace $(CAMUNDA_NAMESPACE) uninstall $(CAMUNDA_RELEASE_NAME)
	-kubectl delete -n $(CAMUNDA_NAMESPACE) pvc -l app.kubernetes.io/instance=$(CAMUNDA_RELEASE_NAME)

.PHONY: clean-camunda
clean-camunda: uninstall-camunda
	-kubectl delete namespace $(CAMUNDA_NAMESPACE)

camunda-values.yaml: delete-camunda-values
	yq eval-all '. as $$item ireduce ({}; . * $$item)' $(CAMUNDA_HELM_VALUES) | \
	sed "s|<CAMUNDA_VERSION>|$(CAMUNDA_VERSION)|g; \
	     s|<YOUR_HOSTNAME>|$(HOST_NAME)|g; \
	     s|<CAMUNDA_CLUSTER_SIZE>|$(CAMUNDA_CLUSTER_SIZE)|g; \
	     s|<CAMUNDA_REPLICATION_FACTOR>|$(CAMUNDA_REPLICATION_FACTOR)|g; \
	     s|<CAMUNDA_PARTITION_COUNT>|$(CAMUNDA_PARTITION_COUNT)|g; \
	     s|<REPLY_EMAIL>|$(REPLY_EMAIL)|g; \
	     s|<KEYCLOAK_ADMIN_USERNAME>|$(KEYCLOAK_ADMIN_USERNAME)|g; \
	     s|<KEYCLOAK_REALM>|$(KEYCLOAK_REALM)|g; \
	     s|<KEYCLOAK_EXT_URL>|$(KEYCLOAK_EXT_URL)|g; \
	     s|<IDENTITY_EXT_URL>|$(IDENTITY_EXT_URL)|g; \
	     s|<ORCHESTRATION_EXT_URL>|$(ORCHESTRATION_EXT_URL)|g; \
	     s|<OPTIMIZE_EXT_URL>|$(OPTIMIZE_EXT_URL)|g; \
	     s|<CONSOLE_EXT_URL>|$(CONSOLE_EXT_URL)|g; \
	     s|<WEB_MODELER_EXT_URL>|$(WEB_MODELER_EXT_URL)|g; \
	     s|<POSTGRES_HOST>|$(POSTGRES_HOST)|g; \
	     s|<POSTGRES_KEYCLOAK_DB>|$(POSTGRES_KEYCLOAK_DB)|g; \
	     s|<POSTGRES_KEYCLOAK_USERNAME>|$(POSTGRES_KEYCLOAK_USERNAME)|g; \
	     s|<POSTGRES_MODELER_DB>|$(POSTGRES_MODELER_DB)|g; \
	     s|<POSTGRES_MODELER_USERNAME>|$(POSTGRES_MODELER_USERNAME)|g; \
	     s|<POSTGRES_CAMUNDA_DB>|$(POSTGRES_CAMUNDA_DB)|g; \
         s|<POSTGRES_CAMUNDA_USERNAME>|$(POSTGRES_CAMUNDA_USERNAME)|g; \
	     s|<POSTGRES_IDENTITY_DB>|$(POSTGRES_IDENTITY_DB)|g; \
	     s|<POSTGRES_IDENTITY_USERNAME>|$(POSTGRES_IDENTITY_USERNAME)|g;" \
	     > ./camunda-values.yaml

.PHONY: create-camunda-credentials
create-camunda-credentials: namespace
	-kubectl delete secret camunda-credentials --namespace $(CAMUNDA_NAMESPACE)
	kubectl create secret generic camunda-credentials \
	  --from-literal=identity-keycloak-admin-password=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-keycloak-user-password=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-first-user-password=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-connectors-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-optimize-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-orchestration-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-console-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-postgresql-admin-password=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-postgresql-user-password=$(DEFAULT_PASSWORD) \
	  --from-literal=webmodeler-postgresql-admin-password=$(DEFAULT_PASSWORD) \
	  --from-literal=webmodeler-postgresql-user-password=$(DEFAULT_PASSWORD) \
	  --from-literal=orchestration-rdbms-password=$(DEFAULT_PASSWORD) \
	  --namespace $(CAMUNDA_NAMESPACE)

.PHONY: port-orchestration
port-orchestration:
	kubectl port-forward svc/$(CAMUNDA_RELEASE_NAME)-zeebe-gateway 8080:8080 -n $(CAMUNDA_NAMESPACE)

.PHONY: port-identity
port-identity:
	kubectl port-forward svc/$(CAMUNDA_RELEASE_NAME)-identity 8084:80 -n $(CAMUNDA_NAMESPACE)

.PHONY: port-keycloak
port-keycloak:
	kubectl port-forward svc/$(CAMUNDA_RELEASE_NAME)-keycloak 18080:80 -n $(CAMUNDA_NAMESPACE)

.PHONY: port-modeler
port-modeler:
	kubectl port-forward svc/$(CAMUNDA_RELEASE_NAME)-web-modeler-webapp 8070:80 -n $(CAMUNDA_NAMESPACE)

.PHONY: port-zeebe # Forward port 26500 to Zeebe Gateway for Zeebe API (gRPC)
port-zeebe:
	kubectl port-forward svc/$(CAMUNDA_RELEASE_NAME)-zeebe-gateway 26500:26500 -n $(CAMUNDA_NAMESPACE)

.PHONY: port-operate
port-operate:
	kubectl port-forward svc/$(CAMUNDA_RELEASE_NAME)-operate 8081:80 -n $(CAMUNDA_NAMESPACE)

.PHONY: port-tasklist
port-tasklist:
	kubectl port-forward svc/$(CAMUNDA_RELEASE_NAME)-tasklist 8082:80 -n $(CAMUNDA_NAMESPACE)

.PHONY: pods
pods:
	 kubectl get pods --namespace $(CAMUNDA_NAMESPACE)

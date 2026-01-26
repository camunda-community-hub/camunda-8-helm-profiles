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
	helm upgrade --install --namespace $(CAMUNDA_NAMESPACE) $(CAMUNDA_RELEASE_NAME) $(CAMUNDA_CHART) -f ./camunda-values.yaml --skip-crds --dry-run --debug

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
	helm template $(CAMUNDA_RELEASE_NAME) $(CAMUNDA_CHART) --values ./camunda-values.yaml --skip-crds --output-dir helm-templates-$(CAMUNDA_RELEASE_NAME)
	@echo "To apply the templates use: kubectl apply -f helm-templates-$(CAMUNDA_RELEASE_NAME) --recursive -n $(CAMUNDA_NAMESPACE)"

.PHONY: update-camunda
update-camunda: camunda-chart
	helm upgrade --namespace $(CAMUNDA_NAMESPACE) $(CAMUNDA_RELEASE_NAME) $(CAMUNDA_CHART) -f ./camunda-values.yaml

.PHONY: delete-camunda-values
delete-camunda-values:
	-rm -f ./camunda-values.yaml

.PHONY: uninstall-camunda
uninstall-camunda:
	-helm --namespace $(namespace) uninstall $(release)
	-kubectl delete -n $(namespace) pvc -l app.kubernetes.io/instance=$(release)

.PHONY: clean-camunda
clean-camunda: uninstall-camunda
	-kubectl delete namespace $(namespace)

camunda-values.yaml: delete-camunda-values
	sed "s|<CAMUNDA_VERSION>|$(CAMUNDA_VERSION)|g; \
	     s|<REPLY_EMAIL>|$(REPLY_EMAIL)|g; \
	     s|<KEYCLOAK_ADMIN_USERNAME>|$(KEYCLOAK_ADMIN_USERNAME)|g; \
	     s|<KEYCLOAK_REALM>|$(KEYCLOAK_REALM)|g; \
	     s|<KEYCLOAK_EXT_URL>|$(KEYCLOAK_EXT_URL)|g; \
	     s|<IDENTITY_EXT_URL>|$(IDENTITY_EXT_URL)|g; \
	     s|<ORCHESTRATION_EXT_URL>|$(ORCHESTRATION_EXT_URL)|g; \
	     s|<OPTIMIZE_EXT_URL>|$(OPTIMIZE_EXT_URL)|g; \
	     s|<CONSOLE_EXT_URL>|$(CONSOLE_EXT_URL)|g;" \
	     $(root)/camunda/values/$(CAMUNDA_VALUES_TEMPLATE) > ./camunda-values.yaml

.PHONY: create-camunda-credentials
create-camunda-credentials: namespace
	-kubectl delete secret camunda-credentials --namespace $(CAMUNDA_NAMESPACE)
	kubectl create secret generic camunda-credentials \
	  --from-literal=identity-keycloak-admin-password=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-first-user-password=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-connectors-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-optimize-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-orchestration-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-console-client-token=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-postgresql-admin-password=$(DEFAULT_PASSWORD) \
	  --from-literal=identity-postgresql-user-password=$(DEFAULT_PASSWORD) \
	  --from-literal=webmodeler-postgresql-admin-password=$(DEFAULT_PASSWORD) \
	  --from-literal=webmodeler-postgresql-user-password=$(DEFAULT_PASSWORD) \
	  --namespace $(CAMUNDA_NAMESPACE)

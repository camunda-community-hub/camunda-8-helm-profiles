.PHONY: create-namespace-keycloak
create-namespace-keycloak:
	-kubectl create namespace $(keycloakNamespace)

.PHONY: clean-namespace-keycloak
clean-namespace-keycloak:
	-kubectl delete namespace $(keycloakNamespace)

keycloak-secrets.yaml:
	sed -e "s/KEYCLOAK_NAMESPACE/$(keycloakNamespace)/g;" -e "s/ADMIN_PASSWORD/$(keycloakBase64EncodedAdminPassword)/g;" -e "s/MANAGEMENT_PASSWORD/$(keycloakBase64EncodedManagementPassword)/g;" $(root)/keycloak/keycloak-secrets.tpl.yaml > $(root)/keycloak/keycloak-secrets.yaml

.PHONY: clean-keycloak-secrets-yaml
clean-keycloak-secrets-yaml:
	-rm $(root)/keycloak/keycloak-secrets.yaml

.PHONY: create-secret-keycloak
create-secret-keycloak: keycloak-secrets.yaml
	-kubectl apply -f $(root)/keycloak/keycloak-secrets.yaml --namespace $(keycloakNamespace)

keycloak-values.yaml:
	sed -e "s|KEYCLOAK_VERSION|$(keycloakVersion)|g;"      \
	-e "s|KEYCLOAK_NAMESPACE|$(keycloakNamespace)|g;"      \
	-e "s|KEYCLOAK_ADMIN_USER|$(keycloakAdminUser)|g;"     \
	-e "s|KEYCLOAK_HOSTNAME|$(keycloakHostName)|g;" \
	-e "s|KEYCLOAK_CONTEXT_PATH|$(keycloakContextPath)|g;" \
	 $(root)/keycloak/keycloak-values.tpl.yaml > $(root)/keycloak/keycloak-values.yaml

.PHONY: clean-keycloak-values-yaml
clean-keycloak-values-yaml:
	-rm $(root)/keycloak/keycloak-values.yaml

.PHONY: install-keycloak
install-keycloak: keycloak-values.yaml
	-helm repo add bitnami https://charts.bitnami.com/bitnami
	-helm repo update bitnami
	-helm upgrade --namespace $(keycloakNamespace) -f $(root)/keycloak/keycloak-values.yaml keycloak bitnami/keycloak --version $(keycloakChartVersion) --atomic --install

.PHONY: port-keycloak
port-keycloak:
	kubectl port-forward svc/keycloak 8080:8080 -n $(namespace)

.PHONY: keycloak-password
keycloak-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(keycloakNamespace) "camunda-keycloak" -o jsonpath="{.data.admin-password}" | base64 --decode))
	@echo KeyCloak Admin password: $(kcPassword)

.PHONY: clean-keycloak
clean-keycloak: clean-namespace-keycloak clean-keycloak-secrets-yaml clean-keycloak-values-yaml

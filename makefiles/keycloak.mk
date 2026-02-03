.PHONY: create-keycloak-admin-user
create-keycloak-admin-user:
	@echo "🔐 creating temporary keycloak admin user ... "

	kubectl exec -it camunda-keycloak-0 --namespace $(CAMUNDA_NAMESPACE) -- \
    env KC_CACHE=local \
    env KC_BOOTSTRAP_ADMIN_PASSWORD=$(KEYCLOAK_TEMP_ADMIN_PASSWORD) \
	/opt/bitnami/keycloak/bin/kc.sh bootstrap-admin user \
	          --db postgres \
	          --no-prompt \
              --username $(KEYCLOAK_TEMP_ADMIN_USERNAME) \
              --password:env KC_BOOTSTRAP_ADMIN_PASSWORD \
              --db-url jdbc:postgresql://$(POSTGRES_HOST):5432/$(POSTGRES_KEYCLOAK_DB) \
              --db-username $(POSTGRES_KEYCLOAK_USERNAME) \
              --db-password $(POSTGRES_KEYCLOAK_PASSWORD) \
              --verbose
	@echo "✅ Created temporary admin account: $(KEYCLOAK_TEMP_ADMIN_USERNAME)"

.PHONY: keycloak-password
keycloak-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(CAMUNDA_NAMESPACE) "$(CAMUNDA_RELEASE_NAME)-keycloak" -o jsonpath="{.data.admin-password}" | base64 --decode))
	@echo KeyCloak Admin password: $(kcPassword)



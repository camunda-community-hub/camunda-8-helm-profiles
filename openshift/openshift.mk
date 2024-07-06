.PHONY: set-config
set-config:
	crc config set enable-cluster-monitoring false
	crc config set disk-size 100
	crc config set memory 20480

.PHONY: kube
kube: set-config
	crc setup

.PHONY: clean-kube
clean-kube:
	-crc delete

.PHONY: config-view
config-view:
	crc config view

.PHONY: stop
stop:
	-crc stop

.PHONY: start
start:
	crc start

.PHONY: restart
restart: stop start

.PHONY: creds
creds:
	crc console --credentials

.PHONY: console
console:
	crc console

.PHONY: use-kube
use-kube:
	oc login -u $(userName) -p $(userSecret) https://api.crc.testing:6443

.PHONY: namespace
namespace:
	-oc create namespace $(namespace)
	-oc config set-context --current --namespace=$(namespace)

.PHONY: camunda
camunda: namespace
	@echo "Attempting to install camunda using chartValues: $(chartValues)"
	helm repo add camunda https://helm.camunda.io
	helm repo update
	helm install --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds \
	  --post-renderer bash --post-renderer-args $(root)/openshift/patch.sh \
	  --version $(camundaHelmVersion)

.PHONY: camunda-template
camunda-template: namespace
	@echo "Attempting to install camunda using chartValues: $(chartValues)"
	helm repo add camunda https://helm.camunda.io
	helm repo update
	helm template --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds \
	  --post-renderer bash --post-renderer-args $(root)/openshift/patch.sh \
	  --version $(camundaHelmVersion) --output-dir .

.PHONY: updateNoAuth
updateNoAuth:
	helm repo update camunda
	helm upgrade --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds \
	  --post-renderer bash --post-renderer-args $(root)/openshift/patch.sh \
	  --version $(camundaHelmVersion)

.PHONY: update
update:
	helm repo update camunda
	CONSOLE_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-console-identity-secret" -o jsonpath="{.data.console-secret}" | base64 --decode) \
	TASKLIST_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-tasklist-identity-secret" -o jsonpath="{.data.tasklist-secret}" | base64 --decode); \
	OPTIMIZE_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-optimize-identity-secret" -o jsonpath="{.data.optimize-secret}" | base64 --decode); \
	OPERATE_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-operate-identity-secret" -o jsonpath="{.data.operate-secret}" | base64 --decode); \
	CONNECTORS_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-connectors-identity-secret" -o jsonpath="{.data.connectors-secret}" | base64 --decode) \
	ZEEBE_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-zeebe-identity-secret" -o jsonpath="{.data.zeebe-secret}" | base64 --decode) \
	KEYCLOAK_ADMIN_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-keycloak" -o jsonpath="{.data.admin-password}" | base64 --decode) \
	KEYCLOAK_MANAGEMENT_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-keycloak" -o jsonpath="{.data.management-password}" | base64 --decode) \
	POSTGRESQL_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-postgresql" -o jsonpath="{.data.postgres-password}" | base64 --decode) \
	helm upgrade --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds \
	  --post-renderer bash --post-renderer-args $(root)/openshift/patch.sh \
	  --version $(camundaHelmVersion) \
      --set global.identity.auth.console.existingSecret=$$CONSOLE_SECRET \
	  --set global.identity.auth.tasklist.existingSecret=$$TASKLIST_SECRET \
	  --set global.identity.auth.optimize.existingSecret=$$OPTIMIZE_SECRET \
	  --set global.identity.auth.operate.existingSecret=$$OPERATE_SECRET \
	  --set global.identity.auth.connectors.existingSecret=$$CONNECTORS_SECRET \
	  --set global.identity.auth.zeebe.existingSecret=$ZEEBE_SECRET \
	  --set identityKeycloak.auth.adminPassword=$$KEYCLOAK_ADMIN_SECRET \
	  --set identityKeycloak.auth.managementPassword=$$KEYCLOAK_MANAGEMENT_SECRET \
	  --set identityKeycloak.postgresql.auth.password=$$IDENTITY_POSTGRESQL_SECRET \
	  --set postgresql.auth.password=$$POSTGRESQL_SECRET

.PHONY: clean-camunda
clean-camunda:
	helm uninstall $(release) --namespace $(namespace)
	oc delete namespace $(namespace)

.PHONY: grant-scc-es
grant-scc-es:
	oc adm policy add-scc-to-user anyuid -z camunda-elasticsearch-master -n $(namespace)
	oc adm policy add-scc-to-user restricted-v2 -z camunda-elasticsearch-master -n $(namespace)
	oc adm policy add-scc-to-user nonroot-v2 -z camunda-elasticsearch-master -n $(namespace)
	oc adm policy add-scc-to-user hostmount-anyuid -z camunda-elasticsearch-master -n $(namespace)
	oc adm policy add-scc-to-user hostnetwork-v2 -z camunda-elasticsearch-master -n $(namespace)

.PHONY: keycloak-password
keycloak-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-keycloak" -o jsonpath="{.data.admin-password}" | base64 --decode))
	@echo KeyCloak Admin password: $(kcPassword)

.PHONY: zeebe-password
zeebe-password:
	$(eval zeebePassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-zeebe-identity-secret" -o jsonpath="{.data.zeebe-secret}" | base64 --decode))
	@echo Zeebe Identity password: $(zeebePassword)

# Uncomment whichever values file is appropriate for your use case
camunda-values-openshift.yaml:
#	cp $(root)/openshift/values/values-dev.yaml $(chartValues)
#	cp $(root)/openshift/values/values-identity-edge.yaml $(chartValues)
	cp $(root)/openshift/values/values-identity-reencrypt.yaml $(chartValues)

.PHONY: keycloak-secret
keycloak-secret:
	kubectl create secret generic keycloak-tls-secret --from-file=$(root)/openshift/certs/keycloak.truststore.jks --from-file=$(root)/openshift/certs/keycloak.keystore.jks

.PHONY: netshoot
netshoot:
	kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -n $(namespace)

.PHONY: camunda
camunda: chart namespace install

.PHONY: install
install:
	@echo "Installing Camunda Platform using chartValues: $(chartValues)"
	helm upgrade --install --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds

# List Helm Chart versions + Camunda Platform versions
.PHONY: versions
versions:
	helm search repo camunda -l

.PHONY: chart
chart:
	helm repo add camunda https://helm.camunda.io
	helm repo update camunda
	helm search repo $(chart)

.PHONY: chart-infos
chart-infos:
	helm search repo $(chart) --output yaml > helm-chart-version.yaml
	helm show values $(chart) > helm-chart-default-values.yaml
	helm show readme $(chart) > helm-chart-readme.md

.PHONY: namespace
namespace:
	-kubectl create namespace $(namespace)
	-kubectl config set-context --current --namespace=$(namespace)

.PHONY: template # generate templates from the camunda helm charts, useful to make some more specific changes which are not doable by the values file.
template: chart
	helm template $(release) $(chart) --values $(chartValues) --skip-crds --output-dir .
	@echo "To apply the templates use: kubectl apply -f camunda-platform --recursive -n $(namespace)"

.PHONY: keycloak-password
keycloak-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-keycloak" -o jsonpath="{.data.admin-password}" | base64 --decode))
	@echo KeyCloak Admin password: $(kcPassword)

.PHONY: config-keycloak
config-keycloak: keycloak-password
	kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=keycloak --timeout=600s
	kubectl -n $(namespace) exec -it $(release)-keycloak-0 -- /opt/bitnami/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE --server http://localhost:8080/auth --realm master --user admin --password $(kcPassword)
	kubectl -n $(namespace) exec -it $(release)-keycloak-0 -- /opt/bitnami/keycloak/bin/kcadm.sh update realms/camunda-platform -s sslRequired=NONE --server http://localhost:8080/auth --realm master --user admin --password $(kcPassword)

.PHONY: zeebe-password
zeebe-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-zeebe-identity-secret" -o jsonpath="{.data.zeebe-secret}" | base64 --decode))
	@echo Zeebe Identity password: $(kcPassword)

.PHONY: connectors-password
connectors-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-connectors-identity-secret" -o jsonpath="{.data.connectors-secret}" | base64 --decode))
	@echo Connectors Identity password: $(kcPassword)

.PHONY: tasklist-password
tasklist-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-tasklist-identity-secret" -o jsonpath="{.data.tasklist-secret}" | base64 --decode))
	@echo Tasklist Identity password: $(kcPassword)

.PHONY: postgresql-password
postgresql-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-postgresql" -o jsonpath="{.data.postgres-password}" | base64 --decode))
	@echo Postgresql password: $(kcPassword)

# Connect to keycloak postgresql db
#export PGUSER="postgres"
#export PGPASSWORD="$(kubectl get secret --namespace camunda "camunda-postgresql" -o jsonpath="{.data.postgres-password}" | base64 --decode)"
#echo ${PGPASSWORD}
#psql -p 5433 -h localhost

.PHONY: docker-registry-password
docker-registry-password:
	$(eval resultPassword := $(shell kubectl get secret --namespace $(namespace) $(camundaDockerRegistrySecretName) --output="jsonpath={.data.\\.dockerconfigjson}" | base64 --decode))
	@echo Docker Registry Config Json: $(resultPassword)

# https://docs.camunda.io/docs/next/self-managed/platform-deployment/helm-kubernetes/deploy/#create-image-pull-secret
.PHONY: create-docker-registry-secret
create-docker-registry-secret: namespace
	kubectl create secret docker-registry $(camundaDockerRegistrySecretName) \
	  --docker-server="$(camundaDockerRegistryUrl)" \
	  --docker-username="$(camundaDockerRegistryUsername)" \
	  --docker-password="$(camundaDockerRegistryPassword)" \
	  --docker-email="$(camundaDockerRegistryEmail)" \
	  --namespace $(namespace)

.PHONY: update
update:
	helm repo update camunda
	helm search repo $(chart)
	OPERATE_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-operate-identity-secret" -o jsonpath="{.data.operate-secret}" | base64 --decode); \
	TASKLIST_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-tasklist-identity-secret" -o jsonpath="{.data.tasklist-secret}" | base64 --decode); \
	OPTIMIZE_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-optimize-identity-secret" -o jsonpath="{.data.optimize-secret}" | base64 --decode); \
	KEYCLOAK_ADMIN_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-keycloak" -o jsonpath="{.data.admin-password}" | base64 --decode) \
	KEYCLOAK_MANAGEMENT_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-keycloak" -o jsonpath="{.data.management-password}" | base64 --decode) \
	POSTGRESQL_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-postgresql" -o jsonpath="{.data.postgres-password}" | base64 --decode) \
        CONNECTORS_SECRET=$$(kubectl get secret --namespace $(namespace) "$(release)-connectors-auth-credentials" -o jsonpath="{.data.connectors-secret}" | base64 -d) \
	helm upgrade --namespace $(namespace) $(release) $(chart) -f $(chartValues) \
	  --set global.identity.auth.operate.existingSecret=$$OPERATE_SECRET \
	  --set global.identity.auth.tasklist.existingSecret=$$TASKLIST_SECRET \
	  --set global.identity.auth.optimize.existingSecret=$$OPTIMIZE_SECRET \
	  --set identity.keycloak.auth.adminPassword=$$KEYCLOAK_ADMIN_SECRET \
	  --set identity.keycloak.auth.managementPassword=$$KEYCLOAK_MANAGEMENT_SECRET \
	  --set identity.keycloak.postgresql.auth.password=$$POSTGRESQL_SECRET \
	  --set connectors.inbound.auth.existingSecret=$CONNECTORS_SECRET

.PHONY: rebalance-leaders-create
rebalance-leaders-create:
	cat $(root)/include/rebalance-leader-job.tpl.yaml | sed -E "s/RELEASE_NAME/$(release)/g" | kubectl apply -n $(namespace) -f -
	-kubectl wait --for=condition=complete job/leader-balancer --timeout=20s       -n $(namespace)

.PHONY: rebalance-leaders-delete
rebalance-leaders-delete:
	cat $(root)/include/rebalance-leader-job.tpl.yaml | sed -E "s/RELEASE_NAME/$(release)/g" | kubectl delete -n $(namespace) -f -

.PHONY: rebalance-leaders
rebalance-leaders: rebalance-leaders-create rebalance-leaders-delete

.PHONY: curl-rebalance # can be used together with `make port-actuator`
curl-rebalance:
	curl -X POST http://localhost:9600/actuator/rebalance

.PHONY: pause-exporters
pause-exporters:
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -i camunda-zeebe-gateway:9600/actuator/exporting/pause -XPOST

.PHONY: resume-exporters
resume-exporters:
	kubectl exec camunda-elasticsearch-master-0 -n $(namespace) -c elasticsearch -- curl -i camunda-zeebe-gateway:9600/actuator/exporting/resume -XPOST


.PHONY: uninstall-camunda
uninstall-camunda:
	-helm --namespace $(namespace) uninstall $(release)
	-kubectl delete -n $(namespace) pvc -l app.kubernetes.io/instance=$(release)
	-kubectl delete -n $(namespace) pvc -l app=elasticsearch-master

.PHONY: clean-camunda
clean-camunda: uninstall-camunda
	-kubectl delete namespace $(namespace)

.PHONY: clean-template # delete the gerenated Helm templates
clean-template:
	rm -r camunda-platform

.PHONY: zeebe-logs
zeebe-logs:
	kubectl logs -f -n $(namespace) -l app.kubernetes.io/component=zeebe-broker

.PHONY: keycloak-logs
keycloak-logs:
	kubectl logs -f -n $(namespace) -l app.kubernetes.io/name=keycloak

.PHONY: identity-logs
identity-logs:
	kubectl logs -f -n $(namespace) -l app.kubernetes.io/name=identity

.PHONY: operate-logs
operate-logs:
	kubectl logs -f -n $(namespace) -l app.kubernetes.io/name=operate

.PHONY: tasklist-logs
tasklist-logs:
	kubectl logs -f -n $(namespace) -l app.kubernetes.io/name=tasklist

.PHONY: es-logs
es-logs:
	kubectl logs -f -n $(namespace) -l app=elasticsearch-master

.PHONY: get-ingress
get-ingress:
	kubectl get ingress -l app.kubernetes.io/name=camunda-platform -o yaml

.PHONY: watch
watch:
	kubectl get pods -w -n $(namespace)

.PHONY: watch-zeebe
watch-zeebe:
	kubectl get pods -w -n $(namespace) -l app.kubernetes.io/name=camunda-platform

.PHONY: await-zeebe
await-zeebe:
	kubectl rollout status --watch statefulset/$(release)-zeebe --timeout=900s -n $(namespace)

.PHONY: zbctl-status
zbctl-status:
	kubectl exec svc/$(release)-zeebe-gateway -n $(namespace) -- zbctl status --insecure

.PHONY: port-zeebe
port-zeebe:
	kubectl port-forward svc/$(release)-zeebe-gateway 26500:26500 -n $(namespace)

.PHONY: port-actuator
port-actuator:
	kubectl port-forward svc/$(release)-zeebe-gateway 9600:9600 -n $(namespace)

.PHONY: port-identity
port-identity:
	kubectl port-forward svc/$(release)-identity 8080:80 -n $(namespace)

.PHONY: port-keycloak
port-keycloak:
	kubectl port-forward svc/$(release)-keycloak 18080:80 -n $(namespace)

.PHONY: port-operate
port-operate:
	kubectl port-forward svc/$(release)-operate 8081:80 -n $(namespace)

.PHONY: port-tasklist
port-tasklist:
	kubectl port-forward svc/$(release)-tasklist 8082:80 -n $(namespace)

.PHONY: port-optimize
port-optimize:
	kubectl port-forward svc/$(release)-optimize 8083:80 -n $(namespace)

.PHONY: port-connectors
port-connectors:
	kubectl port-forward svc/$(release)-connectors 8084:8080 -n $(namespace)

.PHONY: port-postgresql
port-postgresql:
	kubectl port-forward svc/$(release)-postgresql 5433:5432 -n $(namespace)

.PHONY: port-elasticsearch
port-elasticsearch:
	kubectl port-forward svc/elasticsearch-master 9200:9200 -n $(namespace)

.PHONY: pods
pods:
	kubectl get pods --namespace $(namespace)

.PHONY: show-ingress
show-ingress:
	kubectl get ingress --namespace $(namespace)

.PHONY: desc-camunda-ingress
desc-camunda-ingress:
	kubectl describe ingress camunda-camunda-platform --namespace $(namespace)

.PHONY: external-urls-no-ingress
external-urls-no-ingress:
	@echo To access operate: make port-operate, then browse to: http://localhost:8081
	@echo To access tasklist: make port-tasklist, then browse to: http://localhost:8082
	@echo To access inbound connectors: make port-connectors, then browse to: http://localhost:8084/inbound
	@echo To deploy to the cluster: make port-zeebe, then: zbctl status --address localhost:26500 --insecure

.PHONY: help # print this help
help:
	@grep -oP '^\.PHONY: \K.*' $(root)/include/camunda.mk
# TODO print only documented targets	@grep -oP '^\.PHONY: \K.*#.*' $(root)/include/camunda.mk
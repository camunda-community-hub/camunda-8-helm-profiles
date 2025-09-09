.PHONY: camunda # download Helm chart, create namespace, install Camunda Platform
camunda: chart namespace install-camunda

.PHONY: install-camunda # install Camunda Platform
install-camunda:
	@echo "Installing Camunda Platform using chartValues: $(chartValues)"
	helm upgrade --install --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds

.PHONY: dry-run-camunda # perform a dry-run installation of Camunda Platform
dry-run-camunda:
	@echo "Performing a dry-run installation of $(chart) using chartValues: $(chartValues)"
	helm upgrade --install --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds --dry-run --debug

.PHONY: versions # list Helm Chart versions + Camunda Platform versions
versions:
	helm search repo camunda -l

.PHONY: chart # download the Camunda Platform Helm chart
chart:
	helm repo add camunda https://helm.camunda.io
	helm repo update camunda
	helm search repo $(chart)

.PHONY: chart-infos # store Camunda Platform Helm chart version, its values, and readme
chart-infos:
	helm search repo $(chart) --output yaml > helm-chart-version.yaml
	helm show values $(chart) > helm-chart-default-values.yaml
	helm show readme $(chart) > helm-chart-readme.md

.PHONY: namespace # create the Kubernetes namespace
namespace:
	-kubectl create namespace $(namespace)
	-kubectl config set-context --current --namespace=$(namespace)

.PHONY: template # generate templates from the Camunda Helm Chart, useful to make some more specific changes which are not doable by the values file.
template: chart
	helm template $(release) $(chart) --values $(chartValues) --skip-crds --output-dir helm-templates-$(release)
	@echo "To apply the templates use: kubectl apply -f helm-templates-$(release) --recursive -n $(namespace)"

.PHONY: keycloak-password # get the Keycloak admin password
keycloak-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-keycloak" -o jsonpath="{.data.admin-password}" | base64 --decode))
	@echo KeyCloak Admin password: $(kcPassword)

.PHONY: config-keycloak # configure Keycloak
config-keycloak: keycloak-password
	kubectl wait --for=condition=Ready pod -l app.kubernetes.io/component=keycloak --timeout=600s
	kubectl -n $(namespace) exec -it $(release)-keycloak-0 -- /opt/bitnami/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE --server http://localhost:8080/auth --realm master --user admin --password $(kcPassword)
	kubectl -n $(namespace) exec -it $(release)-keycloak-0 -- /opt/bitnami/keycloak/bin/kcadm.sh update realms/camunda-platform -s sslRequired=NONE --server http://localhost:8080/auth --realm master --user admin --password $(kcPassword)

.PHONY: zeebe-password # get the Zeebe Identity password
zeebe-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-zeebe-identity-secret" -o jsonpath="{.data.zeebe-secret}" | base64 --decode))
	@echo Zeebe Identity password: $(kcPassword)

.PHONY: connectors-password # get the Connectors Identity password
connectors-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-connectors-identity-secret" -o jsonpath="{.data.connectors-secret}" | base64 --decode))
	@echo Connectors Identity password: $(kcPassword)

.PHONY: tasklist-password #	get the Tasklist Identity password
tasklist-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-tasklist-identity-secret" -o jsonpath="{.data.tasklist-secret}" | base64 --decode))
	@echo Tasklist Identity password: $(kcPassword)

.PHONY: postgresql-password # get the Postgresql password
postgresql-password:
	$(eval kcPassword := $(shell kubectl get secret --namespace $(namespace) "$(release)-postgresql" -o jsonpath="{.data.postgres-password}" | base64 --decode))
	@echo Postgresql password: $(kcPassword)

# Connect to keycloak postgresql db
#export PGUSER="postgres"
#export PGPASSWORD="$(kubectl get secret --namespace camunda "camunda-postgresql" -o jsonpath="{.data.postgres-password}" | base64 --decode)"
#echo ${PGPASSWORD}
#psql -p 5433 -h localhost

.PHONY: docker-registry-password # get the Docker Registry password
docker-registry-password:
	$(eval resultPassword := $(shell kubectl get secret --namespace $(namespace) $(camundaDockerRegistrySecretName) --output="jsonpath={.data.\\.dockerconfigjson}" | base64 --decode))
	@echo Docker Registry Config Json: $(resultPassword)

# https://docs.camunda.io/docs/next/self-managed/platform-deployment/helm-kubernetes/deploy/#create-image-pull-secret
.PHONY: create-docker-registry-secret # create a Docker Registry secret
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

.PHONY: clean-camunda
clean-camunda: uninstall-camunda
	-kubectl delete namespace $(namespace)

.PHONY: clean-template # delete the gerenated Helm templates
clean-template:
	rm -r helm-templates-$(release)

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

.PHONY: watch # watch all pods in the namespace
watch:
	kubectl get pods --watch -n $(namespace)

.PHONY: watch-events # watch K8s events related to the namespace, e.g. pod scheduling, creation, etc.
watch-events:
	kubectl get events --watch -n $(namespace)

.PHONY: watch-zeebe # watch Zeebe pods
watch-zeebe:
	kubectl get pods --watch -n $(namespace) -l app.kubernetes.io/name=camunda-platform

.PHONY: await-zeebe # wait for Zeebe to be ready
await-zeebe:
	kubectl rollout status --watch statefulset/$(release)-zeebe --timeout=900s -n $(namespace)

.PHONY: await-elasticsearch # wait for Elasticsearch to be ready
await-elasticsearch:
	kubectl rollout status --watch statefulset/$(release)-elasticsearch-master --timeout=900s -n $(namespace)

.PHONY: await-operate # wait for Operate to be ready
await-operate:
	kubectl rollout status --watch deployment/$(release)-operate --timeout=900s -n $(namespace)

.PHONY: await-tasklist # wait for Tasklist to be ready
await-tasklist:
	kubectl rollout status --watch deployment/$(release)-tasklist --timeout=900s -n $(namespace)

.PHONY: await-optimize # wait for Optimize to be ready
await-optimize:
	kubectl rollout status --watch deployment/$(release)-optimize --timeout=900s -n $(namespace)

.PHONY: await-webapps # wait for all web applications (Operate, Tasklist, Optimize) to be ready
await-webapps: await-operate await-tasklist await-optimize

.PHONY: zbctl-status
zbctl-status:
	kubectl exec svc/$(release)-zeebe-gateway -n $(namespace) -- zbctl status --insecure

.PHONY: port-zeebe # Forward port 26500 to Zeebe Gateway for Zeebe API (gRPC)
port-zeebe:
	kubectl port-forward svc/$(release)-zeebe-gateway 26500:gateway -n $(namespace)

.PHONY: port-zeeberest # Forward port 8088 o Zeebe Gateway for Zeebe API (REST)
port-zeeberest:
	kubectl port-forward svc/$(release)-zeebe-gateway 8088:8080 -n $(namespace)

.PHONY: port-camunda # Forward port 8080 to Zeebe Gateway for Camunda 8 API (REST)
port-camunda:
	kubectl port-forward svc/$(release)-zeebe-gateway 8080:rest -n $(namespace)

.PHONY: port-actuator # Forward port 9600 to Zeebe Gateway management API by Spring Boot Actuator
port-actuator:
	kubectl port-forward svc/$(release)-zeebe-gateway 9600:http -n $(namespace)

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

.PHONY: port-elasticsearch # Forward port 9200 to Elasticsearch for REST API
port-elasticsearch:
	kubectl port-forward svc/camunda-elasticsearch 9200:9200 -n $(namespace)

.PHONY: port-elasticsearch-metrics # Forward port 9114 to Elasticsearch for HTTP metrics API
port-elasticsearch-metrics:
	kubectl port-forward svc/camunda-elasticsearch-metrics 9114:http-metrics -n $(namespace)

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
	@grep -oP '^\.PHONY: \K.*' Makefile | sed 's/#/\t/'
	@grep -oP '^\.PHONY: \K.*' $(root)/include/camunda.mk | sed 's/#/\t/'
# TODO follow include statements to print all included targets
# TODO print only documented targets	@grep -oP '^\.PHONY: \K.*#.*' $(root)/include/camunda.mk
# TODO print help in the style of a CLI, e.g. `make help` only lists top-level commands, e.g. watch, await, port, url, open, logs, etc.
# TODO `make help-watch` lists all watch commands, `make help-await` lists all await commands, etc.

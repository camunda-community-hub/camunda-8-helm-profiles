.PHONY: camunda
camunda: namespace
	@echo "Attempting to install camunda using chartValues: $(chartValues)"
	helm repo add camunda https://helm.camunda.io
	helm repo update camunda
	helm search repo $(chart)
	helm install --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds

# List Helm Chart versions + Camunda Platform versions
.PHONY: versions
versions:
	helm search repo camunda -l

.PHONY: namespace
namespace:
	-kubectl create namespace $(namespace)
	-kubectl config set-context --current --namespace=$(namespace)

# Generates templates from the camunda helm charts, useful to make some more specific changes which are not doable by the values file.
.PHONY: template
template:
	helm template $(release) $(chart) -f $(chartValues) --skip-crds --output-dir .
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

.PHONY: rebalance-leaders
rebalance-leaders:
	kubectl exec $$(kubectl get pod --namespace $(namespace) --selector="app=camunda-platform,app.kubernetes.io/component=zeebe-gateway,app.kubernetes.io/instance=camunda,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=zeebe-gateway,app.kubernetes.io/part-of=camunda-platform" --output jsonpath='{.items[0].metadata.name}') --namespace $(namespace) -c zeebe-gateway -- curl -i localhost:9600/actuator/rebalance -XPOST

.PHONY: curl-rebalance # can be used together with `make port-actuator`
curl-rebalance:
	curl -X POST http://localhost:9600/actuator/rebalance

.PHONY: pause-exporters
pause-exporters:
	kubectl exec $$(kubectl get pod --namespace $(namespace) --selector="app=camunda-platform,app.kubernetes.io/component=zeebe-gateway,app.kubernetes.io/instance=camunda,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=zeebe-gateway,app.kubernetes.io/part-of=camunda-platform" --output jsonpath='{.items[0].metadata.name}') --namespace $(namespace) -c zeebe-gateway -- curl -i localhost:9600/actuator/exporting/pause -XPOST
	
.PHONY: resume-exporters
resume-exporters:
	kubectl exec $$(kubectl get pod --namespace $(namespace) --selector="app=camunda-platform,app.kubernetes.io/component=zeebe-gateway,app.kubernetes.io/instance=camunda,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=zeebe-gateway,app.kubernetes.io/part-of=camunda-platform" --output jsonpath='{.items[0].metadata.name}') --namespace $(namespace) -c zeebe-gateway -- curl -i localhost:9600/actuator/exporting/pause -XPOST


.PHONY: uninstall-camunda
uninstall-camunda:
	-helm --namespace $(namespace) uninstall $(release)
	-kubectl delete -n $(namespace) pvc -l app.kubernetes.io/instance=$(release)
	-kubectl delete -n $(namespace) pvc -l app=elasticsearch-master

.PHONY: clean-camunda
clean-camunda: uninstall-camunda
	-kubectl delete namespace $(namespace)

.PHONY: zeebe-logs
zeebe-logs:
	kubectl logs -f -n $(namespace) -l app.kubernetes.io/name=zeebe

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
	kubectl get pods -w -n $(namespace) -l app.kubernetes.io/name=zeebe

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

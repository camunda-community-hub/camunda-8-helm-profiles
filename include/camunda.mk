.PHONY: camunda
camunda: namespace
	helm repo add camunda https://helm.camunda.io
	helm repo update camunda
	helm search repo $(chart)
	helm install --namespace $(namespace) $(release) $(chart) -f camunda-values.yaml --skip-crds

.PHONY: namespace
namespace:
	-kubectl create namespace $(namespace)
	-kubens $(namespace)

# Generates templates from the camunda helm charts, useful to make some more specific changes which are not doable by the values file.
.PHONY: template
template:
	helm template $(release) $(chart) -f camunda-values.yaml --skip-crds --output-dir .
	@echo "To apply the templates use: kubectl apply -f camunda-platform/templates/ -n $(namespace)"

.PHONY: update
update:
	OPERATE_SECRET=$$(kubectl get secret --namespace $(namespace) "camunda-operate-identity-secret" -o jsonpath="{.data.operate-secret}" | base64 --decode); \
	TASKLIST_SECRET=$$(kubectl get secret --namespace $(namespace) "camunda-tasklist-identity-secret" -o jsonpath="{.data.tasklist-secret}" | base64 --decode); \
	OPTIMIZE_SECRET=$$(kubectl get secret --namespace $(namespace) "camunda-optimize-identity-secret" -o jsonpath="{.data.optimize-secret}" | base64 --decode); \
	helm upgrade --namespace $(namespace) $(release) $(chart) -f camunda-values.yaml \
	  --set global.identity.auth.operate.existingSecret=$$OPERATE_SECRET \
	  --set global.identity.auth.tasklist.existingSecret=$$TASKLIST_SECRET \
	  --set global.identity.auth.optimize.existingSecret=$$OPTIMIZE_SECRET

.PHONY: clean-camunda
clean-camunda:
	-helm --namespace $(namespace) uninstall $(release)
	-kubectl delete -n $(namespace) pvc -l app.kubernetes.io/instance=$(release)
	-kubectl delete -n $(namespace) pvc -l app=elasticsearch-master
	-kubectl delete namespace $(namespace)

.PHONY: logs
logs:
	kubectl logs -f -n $(namespace) -l app.kubernetes.io/name=zeebe

.PHONY: watch
watch:
	kubectl get pods -w -n $(namespace)

.PHONY: watch-zeebe
watch-zeebe:
	kubectl get pods -w -n $(namespace) -l app.kubernetes.io/name=zeebe

.PHONY: port-zeebe
port-zeebe:
	kubectl port-forward svc/$(release)-zeebe-gateway 26500:26500 -n $(namespace)

.PHONY: await-zeebe
await-zeebe:
	kubectl wait --for=condition=Ready pod -n $(namespace) -l app.kubernetes.io/name=zeebe --timeout=900s

.PHONY: url-grafana
url-grafana:
	@echo "http://`kubectl get svc metrics-grafana-loadbalancer -n default -o 'custom-columns=ip:status.loadBalancer.ingress[0].ip' | tail -n 1`/d/I4lo7_EZk/zeebe?var-namespace=$(namespace)"

.PHONY: open-grafana
open-grafana:
	xdg-open http://$(shell kubectl get services metrics-grafana-loadbalancer -n default -o jsonpath={..ip})/d/I4lo7_EZk/zeebe?var-namespace=$(namespace) &
.PHONY: metrics
metrics: create-grafana-credentials
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add stable https://charts.helm.sh/stable
	helm repo update prometheus-community stable
	helm install metrics prometheus-community/kube-prometheus-stack --wait --atomic -f $(root)/recipes/metrics/prometheus-operator-values.yml --set prometheusOperator.tlsProxy.enabled=false --namespace default
	kubectl apply -f $(root)/recipes/metrics/grafana-load-balancer.yml -n default
	@${MAKE} grafana-password

.PHONY: grafana-password
grafana-password:
	@echo "Grafana Admin Username: "
	@kubectl get secret grafana-credentials --namespace default \
		-o jsonpath="{.data.admin-user}" | base64 --decode
	@echo ""
	@echo "Grafana Admin Password: "
	@kubectl get secret grafana-credentials --namespace default \
		-o jsonpath="{.data.admin-password}" | base64 --decode
	@echo ""

.PHONY: update-metrics
update-metrics:
	helm upgrade metrics prometheus-community/kube-prometheus-stack --wait --atomic -f $(root)/recipes/metrics/prometheus-operator-values.yml --set prometheusOperator.tlsProxy.enabled=false --namespace default

.PHONY: clean-metrics
clean-metrics:
	-kubectl delete -f $(root)/recipes/metrics/grafana-load-balancer.yml -n default
	-helm uninstall metrics --namespace default
	-kubectl delete -f $(root)/recipes/metrics/grafana-secret.yml -n default
#	-kubectl delete -f $(include-dir)/ssd-storageclass.yaml -n default
	-kubectl delete pvc -l app.kubernetes.io/name=prometheus -n default
	-kubectl delete pvc -l app.kubernetes.io/name=grafana -n default

.PHONY: port-grafana
port-grafana:
	kubectl port-forward svc/metrics-grafana-loadbalancer 8080:80 -n default

.PHONY: port-prometheus
port-prometheus:
	kubectl port-forward svc/metrics-kube-prometheus-st-prometheus 9090:9090 -n default

.PHONY: url-grafana
url-grafana: grafana-password
	@echo "Grafana URL: "
	@echo http://$(shell kubectl get services metrics-grafana-loadbalancer -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}')/d/zeebe-dashboard/zeebe?var-namespace=$(namespace)
	@echo ""

.PHONY: open-grafana
open-grafana:
	xdg-open http://$(shell kubectl get services metrics-grafana-loadbalancer -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}{.status.loadBalancer.ingress[0].hostname}')/d/zeebe-dashboard/zeebe?var-namespace=$(namespace) &

.PHONY: create-grafana-credentials
create-grafana-credentials:
	-kubectl delete secret grafana-credentials --namespace default
	kubectl create secret generic grafana-credentials \
	  --from-literal=admin-user=camunda \
	  --from-literal=admin-password=$(GRAFANA_PASSWORD) \
	  --namespace default
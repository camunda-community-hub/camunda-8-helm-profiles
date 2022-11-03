.PHONY: metrics
metrics:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add stable https://charts.helm.sh/stable
	helm repo update prometheus-community stable
	kubectl apply -f $(root)/metrics/grafana-secret.yml -n default
	helm install metrics prometheus-community/kube-prometheus-stack --wait --atomic -f $(root)/metrics/prometheus-operator-values.yml --set prometheusOperator.tlsProxy.enabled=false --namespace default
	kubectl apply -f $(root)/metrics/grafana-load-balancer.yml -n default

.PHONY: clean-metrics
clean-metrics:
	-kubectl delete -f $(root)/metrics/grafana-load-balancer.yml -n default
	-helm uninstall metrics --namespace default
	-kubectl delete -f $(root)/metrics/grafana-secret.yml -n default
#	-kubectl delete -f $(include-dir)/ssd-storageclass.yaml -n default
	-kubectl delete pvc -l app.kubernetes.io/name=prometheus -n default
	-kubectl delete pvc -l app.kubernetes.io/name=grafana -n default

.PHONY: url-grafana
url-grafana:
	@echo "http://`kubectl get svc metrics-grafana-loadbalancer -n default -o 'custom-columns=ip:status.loadBalancer.ingress[0].ip' | tail -n 1`/d/I4lo7_EZk/zeebe?var-namespace=$(namespace)"

.PHONY: port-grafana
port-grafana:
	kubectl port-forward svc/metrics-grafana-loadbalancer 8080:80 -n default

.PHONY: port-prometheus
port-prometheus:
	kubectl port-forward svc/metrics-kube-prometheus-st-prometheus 9090:9090 -n default

.PHONY: open-grafana
open-grafana:
	xdg-open http://$(shell kubectl get services metrics-grafana-loadbalancer -n default -o jsonpath={..ip})/d/I4lo7_EZk/zeebe?var-namespace=$(namespace) &
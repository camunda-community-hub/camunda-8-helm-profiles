.PHONY: metrics
metrics:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add stable https://charts.helm.sh/stable
	helm repo update prometheus-community stable
	kubectl apply -f ../metrics/grafana-secret.yml -n default
	helm install metrics prometheus-community/kube-prometheus-stack --wait --atomic -f ../metrics/prometheus-operator-values.yml --set prometheusOperator.tlsProxy.enabled=false --namespace default
	kubectl apply -f ../metrics/grafana-load-balancer.yml -n default

.PHONY: clean-metrics
clean-metrics:
	-kubectl delete -f ../metrics/grafana-load-balancer.yml -n default
	-helm uninstall metrics --namespace default
	-kubectl delete -f ../metrics/grafana-secret.yml -n default
#	-kubectl delete -f $(include-dir)/ssd-storageclass.yaml -n default
	-kubectl delete pvc -l app.kubernetes.io/name=prometheus -n default
	-kubectl delete pvc -l app.kubernetes.io/name=grafana -n default

.PHONY: url-grafana
url-grafana:
	@echo "http://`kubectl get svc metrics-grafana-loadbalancer -o 'custom-columns=ip:status.loadBalancer.ingress[0].ip' -n default | tail -n 1`/d/I4lo7_EZk/zeebe"

.PHONY: port-grafana
port-grafana:
	kubectl port-forward svc/metrics-grafana-loadbalancer 8080:80 -n default

.PHONY: port-prometheus
port-prometheus:
	kubectl port-forward svc/metrics-kube-prometheus-st-prometheus 9090:9090 -n default

.PHONY: open-grafana
open-grafana:
	xdg-open http://$(shell kubectl get services metrics-grafana-loadbalancer -o jsonpath={..ip} -n default)/d/I4lo7_EZk/zeebe &
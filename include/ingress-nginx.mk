.PHONY: ingress
ingress: ingress-nginx camunda-values-nginx.yaml

.PHONY: ingress-nginx
ingress-nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait

.PHONY: ingress-ip-from-service
ingress-ip-from-service:
	$(eval IP := $(shell kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.ip}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1))
	@echo "Ingress controller uses IP address: $(IP)"

camunda-values-nginx.yaml: ingress-ip-from-service
	sed "s/127.0.0.1/$(IP)/g;" ../ingress-nginx/camunda-values.yaml > ./camunda-values-nginx.yaml

.PHONY: clean-ingress
clean-ingress:
	-helm --namespace ingress-nginx uninstall ingress-nginx
	-kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	-kubectl delete namespace ingress-nginx


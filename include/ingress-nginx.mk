.PHONY: ingress
ingress: ingress-nginx ingress-ip-from-service

.PHONY: ingress-nginx
ingress-nginx:
	-kubectl create namespace ingress-nginx
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx

.PHONY: ingress-ip-from-service
ingress-ip-from-service:
	IP=$$(kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.ip}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1) ; \
	sed -i.bak "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$$IP/g" camunda-values.yaml ; \
	echo "Ingress controller ready at: http://$$IP.nip.io"

.PHONY: ingress-ip-from-commandline
ingress-ip-from-commandline:
	@echo "Enter Load Balancer IP Address: " ; \
	read IP; \
	sed -i.bak "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$$IP/g" camunda-values.yaml ; \
	echo "Ingress controller ready at: http://$$IP.nip.io"

.PHONY: clean-ingress
clean-ingress: clean-ingress-ip
	-helm --namespace ingress-nginx uninstall ingress-nginx
	-kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	-kubectl delete namespace ingress-nginx

.PHONY: clean-ingress-ip
clean-ingress-ip:
	sed -i.bak "s/([0-9]{1,3}\.){3}[0-9]{1,3}/127.0.0.1/g" camunda-values.yaml

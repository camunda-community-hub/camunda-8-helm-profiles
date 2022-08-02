.PHONY: ingress
ingress: ingress-nginx ingress-ip

.PHONY: ingress-nginx
ingress-nginx:
	-kubectl create namespace ingress-nginx
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx

# dig +short a6e4157656634474fb0c4480dd894683-683984428.us-east-1.elb.amazonaws.com
# nslookup a6e4157656634474fb0c4480dd894683-683984428.us-east-1.elb.amazonaws.com
.PHONY: ingress-ip
ingress-ip:
	IP=$$(kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.ip}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1) ; \
	sed -Ei '' "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$$IP/g" camunda-values.yaml ; \
	echo "Ingress controller ready at: http://$$IP.nip.io"

.PHONY: clean-ingress
clean-ingress: clean-ingress-ip
	-helm --namespace ingress-nginx uninstall ingress-nginx
	-kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	-kubectl delete namespace ingress-nginx

.PHONY: clean-ingress-ip
clean-ingress-ip:
	sed -Ei '' "s/([0-9]{1,3}\.){3}[0-9]{1,3}/127.0.0.1/g" camunda-values.yaml

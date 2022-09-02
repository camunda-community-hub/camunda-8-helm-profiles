
.PHONY: ingress
ingress: namespace ingress-ip-from-commandline ingress-azure

.PHONY: ingress-azure
ingress-azure:
	kubectl apply -f ingress-azure.yaml

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
	sed -i.bak "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$$IP/g" ingress-azure.yaml ; \
	echo "Ingress controller ready at: http://$$IP.nip.io"

.PHONY: clean-ingress
clean-ingress: clean-ingress-ip
	kubectl delete ingress ingress-azure -n camunda

.PHONY: clean-ingress-ip
clean-ingress-ip:
	sed -i.bak "s/([0-9]{1,3}\.){3}[0-9]{1,3}/127.0.0.1/g" camunda-values.yaml ; \
	sed -i.bak "s/([0-9]{1,3}\.){3}[0-9]{1,3}/127.0.0.1/g" ingress-azure.yaml ; \

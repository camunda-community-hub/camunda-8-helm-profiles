
.PHONY: ingress
ingress: namespace ingress-ip-from-commandline ingress-ip ingress-azure

.PHONY: ingress-azure
ingress-azure:
	kubectl apply -f ingress-azure.yaml

.PHONY: ingress-ip-from-commandline
ingress-ip-from-commandline:
	@echo "Enter IP Address of AWS Load Balancer: "; \
	read IP;
	@echo "IP Address: $$IP"

.PHONY: ingress-ip
ingress-ip:
	sed -Ei '' "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$$IP/g" camunda-values.yaml ; \
	sed -Ei '' "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$$IP/g" ingress-azure.yaml ; \
	echo "Ingress controller ready at: http://$$IP.nip.io"

.PHONY: clean-ingress
clean-ingress: clean-ingress-ip
	kubectl delete ingress ingress-azure -n camunda

.PHONY: clean-ingress-ip
clean-ingress-ip:
	sed -Ei '' "s/([0-9]{1,3}\.){3}[0-9]{1,3}/127.0.0.1/g" camunda-values.yaml ; \
	sed -Ei '' "s/([0-9]{1,3}\.){3}[0-9]{1,3}/127.0.0.1/g" ingress-azure.yaml ; \

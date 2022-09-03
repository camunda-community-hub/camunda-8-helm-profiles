.PHONY: azure-gateway-ip-address
azure-gateway-ip-address:
	$(eval IP := $(shell az network public-ip show -g $(nodeResourceGroup) -n $(gatewayName)-appgwpip -o json --query ipAddress | xargs))

camunda-values-azure.yaml: azure-gateway-ip-address
	sed "s/127.0.0.1/$(IP)/g;" ../ingress-nginx/camunda-values.yaml > ./camunda-values-azure.yaml

.PHONY: ingress-azure
ingress-azure: namespace azure-gateway-ip-address
	echo "Creating ingress controller at: http://$(IP).nip.io" ;
	cat ingress-azure.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -f -

.PHONY: clean-ingress-azure
clean-ingress-azure:
	kubectl delete ingress ingress-azure -n camunda

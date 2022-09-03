
.PHONY: ingress
ingress: namespace ingress-azure

.PHONY: ingress-azure
ingress-azure:
	$(eval IP := $(shell az network public-ip show -g $(nodeResourceGroup) -n $(gatewayName)-appgwpip -o json --query ipAddress | xargs))
	echo "Creating ingress controller at: http://$(IP).nip.io" ;
	cat ingress-azure.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -f -

.PHONY: clean-ingress
clean-ingress: clean-ingress-ip
	kubectl delete ingress ingress-azure -n camunda

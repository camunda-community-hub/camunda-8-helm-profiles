# https://cert-manager.io/docs/tutorials/acme/nginx-ingress/
.PHONY: cert-manager
cert-manager: 
	kubectl create namespace cert-manager
	helm repo add jetstack https://charts.jetstack.io
	helm repo update
	helm install cert-manager jetstack/cert-manager \
	--namespace cert-manager \
  	--create-namespace \
  	--version v1.9.1 \
	--set installCRDs=true

.PHONY: issuers
issuers:
	cat letsencypt-staging.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | kubectl create -n cert-manager -f -
	cat letsencypt-prod.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | kubectl create -n cert-manager -f -
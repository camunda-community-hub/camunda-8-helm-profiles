# https://cert-manager.io/docs/tutorials/acme/nginx-ingress/
prodserver ?= https:\\/\\/acme-v02.api.letsencrypt.org/directory

.PHONY: cert-manager
cert-manager: 
	helm repo add jetstack https://charts.jetstack.io
	helm repo update
	helm install cert-manager jetstack/cert-manager \
	--namespace cert-manager \
  	--create-namespace \
  	--version v1.9.1 \
	--set installCRDs=true

.PHONY: letsencypt-staging
letsencypt-staging:
	cat ../include/letsencypt.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | kubectl create -n cert-manager -f -
	
.PHONY: letsencypt-prod
letsencypt-prod:
	cat ../include/letsencypt.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | sed -E "s/acme-staging-v02/acme-v02/g" | kubectl apply -n cert-manager -f -

.PHONY: letsencypt-prod-patch
letsencypt-prod-patch:
	kubectl patch ClusterIssuer letsencrypt --type json -p '[{"op": "replace", "path": "/spec/acme/sever", "value":"$(prodserver)"}]'
	kubectl describe ClusterIssuer letsencrypt | grep letsencrypt.org

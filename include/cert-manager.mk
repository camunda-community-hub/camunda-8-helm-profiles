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
	cat $(root)/include/letsencrypt.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | kubectl create -n cert-manager -f -
	
.PHONY: letsencypt-prod
letsencypt-prod:
	cat $(root)/include/letsencrypt.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | sed -E "s/acme-staging-v02/acme-v02/g" | kubectl apply -n cert-manager -f -

#TODO: succeeds, but does not seem to have right effect
.PHONY: letsencypt-prod-patch
letsencypt-prod-patch:
	kubectl patch ClusterIssuer letsencrypt --type json -p '[{"op": "replace", "path": "/spec/acme/sever", "value":"$(prodserver)"}]'
	kubectl describe ClusterIssuer letsencrypt | grep letsencrypt.org

.PHONY: annotate-ingress-tls
annotate-ingress-tls:
	kubectl -n $(namespace) annotate ingress camunda-camunda-platform cert-manager.io/cluster-issuer=letsencrypt
	make get-ingress

# clean cert-manager and cluster issuer
.PHONY: clean-cert-manager
clean-cert-manager:
	helm --namespace cert-manager delete cert-manager
	kubectl delete namespace cert-manager
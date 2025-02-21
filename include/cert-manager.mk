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

.PHONY: letsencrypt-staging
letsencrypt-staging:
	cat $(root)/include/letsencrypt-stage.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | kubectl apply -n cert-manager -f -
	
.PHONY: letsencrypt-prod
letsencrypt-prod:
	cat $(root)/include/letsencrypt-prod.yaml | sed -E "s/someone@somewhere.io/$(certEmail)/g" | kubectl apply -n cert-manager -f -

#TODO: succeeds, but does not seem to have right effect
.PHONY: letsencrypt-prod-patch
letsencrypt-prod-patch:
	kubectl patch ClusterIssuer letsencrypt --type json -p '[{"op": "replace", "path": "/spec/acme/server", "value":"$(prodserver)"}]'
	kubectl describe ClusterIssuer letsencrypt | grep letsencrypt.org

.PHONY: annotate-remove-ingress-tls
annotate-remove-ingress-tls:
	kubectl -n $(namespace) annotate ingress camunda-camunda-platform cert-manager.io/cluster-issuer-
	make get-ingress

.PHONY: annotate-ingress-tls
annotate-ingress-tls: annotate-remove-ingress-tls
	kubectl -n $(namespace) annotate ingress camunda-camunda-platform cert-manager.io/cluster-issuer=letsencrypt
	make get-ingress

.PHONY: annotate-letsencrypt-stage
annotate-letsencrypt-stage: annotate-remove-ingress-tls
	kubectl -n $(namespace) annotate ingress camunda-camunda-platform cert-manager.io/cluster-issuer=letsencrypt-stage
	make get-ingress

# clean cert-manager and cluster issuer
.PHONY: clean-cert-manager
clean-cert-manager:
	helm --namespace cert-manager delete cert-manager
	kubectl delete namespace cert-manager

# create a secret containing a cacerts truststore containing the lets encrypt staging CA certificates
.PHONY: cacerts-staging
cacerts-staging:
	-kubectl create secret generic "cacerts-staging" \
	--namespace=$(namespace) \
	--from-file=cacerts_staging=$(root)/include/cacerts_staging

.PHONY: get-cert-requests
get-cert-requests:
	-kubectl get certificaterequests --namespace $(namespace)

.PHONY: get-cert-orders
get-cert-orders:
	-kubectl get orders --namespace $(namespace)

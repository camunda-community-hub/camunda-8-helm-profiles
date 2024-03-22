# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

certEmail ?= SOME_EMAIL

service ?= zeebe-gateway
# TLS secret name
secretName ?= tls-secret
# Cert Signing Reqest (CSR) signer name
signerName ?= 127.0.0.1.nip.io\/pdiddy

# fully qualified domain name
fqdn ?= 127.0.0.1.nip.io

# ------------------------------------
# Camunda Enterprise Docker Registry Login

camundaDockerRegistrySecretName ?= camunda-docker-registry-secret
camundaDockerRegistryUrl ?= registry.camunda.cloud
camundaDockerRegistryUsername ?= USERNAME
camundaDockerRegistryPassword ?= PASSWORD
camundaDockerRegistryEmail ?= SOME_EMAIL

# ------------------------------------
# The following variables should not be changed except for advanced use cases

root ?= $(shell pwd)/../../../..

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
# chart ?= /Users/paullungu/projects/camunda-platform-helm/charts/camunda-platform
chart ?= camunda/camunda-platform

#chartValues ?= $(root)/development/camunda-values.yaml
chartValues ?= $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml

.PHONY: def
def: ingress-nginx-kind cert-manager letsencrypt-prod camunda-cfssl

.PHONY: camunda-all
camunda-all: camunda-values-nginx-localhost.yaml namespace \
	create-docker-registry-secret \
	camunda \
	kube-create-secret \
	annotate-ingress-tls \
  external-urls

.PHONY: camunda-cfssl
camunda-cfssl: camunda-values-nginx-localhost.yaml namespace \
	create-docker-registry-secret \
	create-zeebe-gateway-certs \
	camunda \
	kube-create-secret \
	annotate-ingress-tls \
	annotate-ingress-proxy-buffer-size \
	external-urls

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gateway required)
.PHONY: kube
kube: kube-kind

# 1 cert-manager from cert-manager.mk: create certificate manager for tls

# 2 letsencrypt-staging/-prod from cert-manager.mk: create letsencrypt cert issuer

# 3 create nginx ingress controller with dns and tls

# 4 create camunda-values-nginx-localhost.yaml with localhost ip
camunda-values-nginx-localhost.yaml:
	-rm -Rf $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml
	sed "s/YOUR_HOSTNAME/$(fqdn)/g; s/REGISTRY_SECRET/$(camundaDockerRegistrySecretName)/g; s/SECRET_NAME/$(secretName)/g;" $(root)/kind/ingress/nginx/tls/camunda-values.yaml > $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml
	# sed "s/YOUR_HOSTNAME/127.0.0.1.nip.io/g;" $(root)/kind/ingress/nginx/tls/camunda-values.yaml > $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml

# 5 helm install camunda from camunda.mk with own tls config, combined ingress
# .PHONY: camunda
# camunda: namespace create-docker-registry-secret create-zeebe-gateway-certs
# 	@echo "Attempting to install camunda using chartValues: $(chartValues)"
# 	helm repo add camunda https://helm.camunda.io
# 	helm repo update camunda
# 	helm search repo $(chart)
# 	helm install --namespace $(namespace) $(release) $(chart) -f $(chartValues) --skip-crds

# 6 annotate-ingress-tls from cert-manager.mk: add cluster-issuer annotation to nginx

# 7 annotate-ingress-proxy-buffer-size from ingress-nginx.mk: nginx.ingress.kubernetes.io/proxy-buffer-size": "128k"

# 8 create-zeebe-gateway-certs
.PHONY: create-zeebe-gateway-certs
create-zeebe-gateway-certs: clean-certs cfssl-create-csr kube-upload-csr kube-approve-csr \
	 cfssl-create-cert-authority cfssl-sign-certificate \
	 kube-upload-cert kube-create-secret kube-get-client-cert kube-create-client-cert

# 9 Show external URLs
.PHONY: external-urls
external-urls:
	@echo https://127.0.0.1.nip.io/auth
	@echo https://127.0.0.1.nip.io/identity
	@echo https://127.0.0.1.nip.io/operate
	@echo https://127.0.0.1.nip.io/tasklist
	@echo https://127.0.0.1.nip.io/optimize
	@echo https://127.0.0.1.nip.io/webmodeler
	@echo https://127.0.0.1.nip.io/console
	@echo zbctl status --address 127.0.0.1.nip.io:443

.PHONY: setup-keycloak
setup-keycloak:	create-namespace-keycloak create-secret-keycloak keycloak-values-ip install-keycloak

.PHONY: clean
clean: clean-app clean-ingress-kind clean-cert-manager

.PHONY: clean-app
clean-app: clean-camunda
	rm -f $(root)/kind/ingress/nginx/tls/camunda-values-nginx-localhost.yaml

.PHONY: clean-kube
clean-kube: clean-kube-kind

include $(root)/include/camunda.mk
include $(root)/include/ingress-nginx.mk
include $(root)/include/cert-manager.mk
include $(root)/kind/include/kubernetes-kind.mk
include $(root)/keycloak/keycloak.mk
include $(root)/cfssl/cfssl-certs.mk
include $(root)/metrics/metrics.mk

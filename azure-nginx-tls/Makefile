# Set these values to what you want for your specific environment
namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
region ?= eastus
clusterName ?= camunda-greenfield-01
machineType ?= Standard_A8_v2
minSize ?= 1
maxSize ?= 6
# These must be set to match resources that already exist inside an existing Azure Environment
resourceGroup ?= greenfield-group-01
chartValues ?= camunda-values-nginx.yaml
dnsLabel ?= camapac
certEmail ?= robert.emsbach@camunda.com

# 0 kube from kube-azure via include: Create kubernetes cluster. 
# Include ingress-azure from greenfiled\kubernetes-azure.mk not suitable, no aplication gatewya required here.

.PHONY: all
all: cert-manager issuers ingress camunda config-keycloak ingress-nginx-update external-urls

# 1 cert-manager from cert-manager.mk via include: create certificate manager for tls

# 2 issuers from cert-manager.mk via include: create letsencypt cert issuers

# 3 ingress from ingress-nginx.mk via include: create ingress-nginx and camunda-values-nginx.yaml

# 4 camunda from camunda.mk via include

# 5 config-keycloak from camunda.mk via include

# 6 aply routes to ingress. Can't use ingress-azure via include as it expects a setup with application gateway
.PHONY: ingress-nginx-update
ingress-nginx-update: ingress-ip-from-service
	@echo "Configuring ingress controller routes for: http://$(IP).nip.io" ;
	cat ingress-nginx.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -n ingress-nginx -f -

.PHONY: ingress-zeebe-update
ingress-zeebe-update: ingress-ip-from-service
	@echo "Configuring ingress controller routes for: http://$(IP).nip.io" ;
	cat zeebe-ingress.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -n camunda -f -

# 7 Show external URLs for web applications
.PHONY: external-urls
external-urls: ingress-ip-from-service
	@echo https://keycloak.$(IP).nip.io
	@echo https://identity.$(IP).nip.io
	@echo https://operate.$(IP).nip.io
	@echo https://optimize.$(IP).nip.io

# <--- End of setup --->

# Remove nginx ingress and Camunda from cluster
.PHONY: clean
clean: clean-ingress clean-camunda
	rm -f camunda-values-nginx.yaml

.PHONY: clean-cert-manager
clean-cert-manager:
	helm --namespace cert-manager delete cert-manager
	kubectl delete namespace cert-manager

.PHONY: add-dnsLabel
add-dnsLabel: 
# $(eval publicIpId=$(shell az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$(IP)')].[id]" --output tsv))
# az network public-ip update --ids $(publicIpId) --dns-name $(dnsLabel)
# az network public-ip show --ids $(publicIpId) --query "[dnsSettings.fqdn]" --output tsv
	helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
	--namespace ingress-nginx \
	--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(dnsLabel) \
  	--set controller.service.loadBalancerIP=$(IP)

include ../include/kube-azure.mk
include ../include/cert-manager.mk
include ../include/ingress-nginx.mk
include ../include/camunda.mk

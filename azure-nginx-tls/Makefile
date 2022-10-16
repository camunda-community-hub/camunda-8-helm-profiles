# Set these values to what you want for your specific environment
namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
region ?= eastus
clusterName ?= cam-aks
machineType ?= Standard_A8_v2
minSize ?= 1
maxSize ?= 6
# These must be set to match resources that already exist inside an existing Azure Environment
resourceGroup ?= camunda-rg
chartValues ?= camunda-values-nginx-tls.yaml
dnsLabel ?= camundaapac
certEmail ?= robert.emsbach@camunda.com
fqdn ?= ${dnsLabel}.${region}.cloudapp.azure.com

# 0 kube from kube-azure via include: Create kubernetes cluster. 
# Include ingress-azure from greenfiled\kubernetes-azure.mk not suitable, no aplication gatewya required here.

.PHONY: all
all: cert-manager letsencypt-staging nginx-dns-tls camunda-values-nginx-tls.yaml camunda config-keycloak external-urls

# 1 cert-manager from cert-manager.mk via include: create certificate manager for tls

# 2 letsencypt-staging from cert-manager.mk via include: create letsencypt cert issuer

# ingress-nginx from ingress-nginx.mk via include: create nginx ingress controller
# 3 nginx-letsencypt from ingress-nginx.mk via include: update ingress controller with letsencrypt

# dnsLabel : add fully qulaified domain name: ${dnsLabel}.${region}.cloudapp.azure.com
.PHONY: nginx-dns-tls
nginx-dns-tls: 
# $(eval publicIpId=$(shell az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$(IP)')].[id]" --output tsv))
# az network public-ip update --ids $(publicIpId) --dns-name $(dnsLabel)
# az network public-ip show --ids $(publicIpId) --query "[dnsSettings.fqdn]" --output tsv
#	-kubectl create namespace ingress-nginx
#	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
#	helm repo update ingress-nginx
#	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(dnsLabel) \
	--set controller.service.annotations."cert-manager.io/cluster-issuer"="letsencrypt"
	@echo $(fqdn)

# --set controller.service.loadBalancerIP=$(IP)
# 4 create camunda-values-nginx.yaml with external ip from ingress-nginx-controller's Loadbalancer
.PHONY: camunda-values-nginx-tls.yaml
camunda-values-nginx-tls.yaml: ingress-ip-from-service
	sed "s/mydnslabel.eastus.cloudapp.azure.com/$(fqdn)/g;" camunda-values.yaml > ./$(chartValues)
#	sed "s/127.0.0.1.nip.io/$(fqdn)/g;" camunda-values.yaml > ./$(chartValues)
	

# 5 camunda from camunda.mk via include: install camunda helm chart

# 6 config-keycloak from camunda.mk via include: let keycloak allow non-ssl connections

#  7 Apply routes to ingress. Can't use ingress-azure via include as it expects a setup with application gateway
# .PHONY: ingress-nginx-update
# ingress-nginx-update: ingress-ip-from-service
# 	@echo "Configuring ingress controller routes for: http://$(IP).nip.io" ;
# 	cat ingress-nginx.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -n ingress-nginx -f -

.PHONY: ingress-zeebe-update
ingress-zeebe-update: ingress-ip-from-service
	@echo "Configuring ingress controller routes for: http://$(IP).nip.io" ;
	cat zeebe-ingress.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -n camunda -f -

# 8 Show external URLs for web applications
.PHONY: external-urls
external-urls: ingress-ip-from-service
	@echo https://$(fqdn)/auth
	@echo https://$(fqdn)/identity
	@echo https://$(fqdn)/operate
	@echo https://$(fqdn)/tasklist
	@echo https://$(fqdn)/optimize
	@echo zeebe.$(fqdn):26500


.PHONY: zb-status
zb-status: ingress-ip-from-service
	set ZEEBE_ADDRESS=zeebe.$(IP).nip:26500
	zbctl status --insecure

# zbctl --insecure deploy /mnt/c/Users/Rob/Downloads/onetask.bpmn
# zbctl --insecure create instance MyProcess

# <--- End of setup --->

# Remove nginx ingress and Camunda from cluster
.PHONY: clean
clean: clean-ingress clean-camunda
	rm -f $(chartValues)

.PHONY: clean-cert-manager
clean-cert-manager:
	helm --namespace cert-manager delete cert-manager
	kubectl delete namespace cert-manager

include ../include/kube-azure.mk
include ../include/cert-manager.mk
include ../include/ingress-nginx.mk
include ../include/azure-fileshare.mk
include ../include/camunda.mk

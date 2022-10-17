root ?= /home/rob/helm-profiles/
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

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gatewya required)

.PHONY: all
all: cert-manager letsencypt-staging nginx-dns-tls camunda-values-nginx-tls.yaml camunda config-keycloak external-urls

# 1 cert-manager from cert-manager.mk: create certificate manager for tls

# 2 letsencypt-staging from cert-manager.mk: create letsencypt cert issuer

# 3 create nginx ingress controller with dns and tls
.PHONY: nginx-dns-tls
nginx-dns-tls: 
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(dnsLabel) \
	--set controller.service.annotations."cert-manager.io/cluster-issuer"="letsencrypt"
	@echo $(fqdn)

# 4 create camunda-values-nginx.yaml with external ip from ingress controller's Loadbalancer
.PHONY: camunda-values-nginx-tls.yaml
camunda-values-nginx-tls.yaml:
	@echo Ingress controller will use fqdn: $(fqdn).$(region).cloudapp.azure.com
	@sed "s/mydnslabel.$(region).cloudapp.azure.com/$(fqdn)/g;" camunda-values.yaml > ./$(chartValues)

# 5 helm install camunda from camunda.mk with own tls config, combined ingress

# 6 config-keycloak from camunda.mk: let keycloak allow non-ssl connections

# 7 Show external URLs
.PHONY: external-urls
external-urls: ingress-ip-from-service
	@echo https://$(fqdn)/auth
	@echo https://$(fqdn)/identity
	@echo https://$(fqdn)/operate
	@echo https://$(fqdn)/tasklist
	@echo https://$(fqdn)/optimize
	@echo zeebe.$(fqdn):26500

# <--- End of setup --->

# Remove nginx ingress and Camunda from cluster
.PHONY: clean
clean: clean-ingress clean-camunda
	rm -f $(chartValues)

# clean cert-manager and cluster issuer
.PHONY: clean-cert-manager
clean-cert-manager:
	helm --namespace cert-manager delete cert-manager
	kubectl delete namespace cert-manager

include $(root)include/camunda.mk
include $(root)include/ingress-nginx.mk
include $(root)include/cert-manager.mk
include $(root)azure/include/cluster.mk
include $(root)include/zbctl.mk
include $(root)azure/include/fileshare.mk




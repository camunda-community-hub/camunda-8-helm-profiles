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
dnsLabel ?= camapac
certEmail ?= robert.emsbach@camunda.com
fqdn ?= ${dnsLabel}.${region}.cloudapp.azure.com
# fqdn = $(IP).nip.io

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gatewya required)

.PHONY: all
all: cert-manager letsencypt-prod nginx-dns-tls camunda-values-nginx-tls.yaml camunda annotate-ingress-tls external-urls

# 1 cert-manager from cert-manager.mk: create certificate manager for tls

# 2 letsencypt-staging/-prod from cert-manager.mk: create letsencypt cert issuer

# 3 create nginx ingress controller with dns and tls
.PHONY: nginx-dns-tls
nginx-dns-tls: 
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(dnsLabel) \
	--set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
	--set controller.service.annotations."cert-manager.io/cluster-issuer"="letsencrypt"

# 4 create camunda-values-nginx.yaml with external ip from ingress controller's Loadbalancer
.PHONY: camunda-values-nginx-tls.yaml
camunda-values-nginx-tls.yaml: ingress-ip-from-service
	@echo Ingress controller will use fqdn: $(fqdn)
	@sed "s/dnslabel.location.cloudapp.azure.com/$(fqdn)/g;" camunda-values.yaml > ./$(chartValues)
#	@sed "s/mydnslabel.$(region).cloudapp.azure.com/$(fqdn)/g;" camunda-values.yaml > ./$(chartValues)

# 5 helm install camunda from camunda.mk with own tls config, combined ingress

# 6 annotate-ingress-tls from cert-manager.mk: add cluster-issuer annotation to nginx

# 7 Show external URLs
.PHONY: external-urls
external-urls: ingress-ip-from-service
	@echo https://$(fqdn)/auth
	@echo https://$(fqdn)/identity
	@echo https://$(fqdn)/operate
	@echo https://$(fqdn)/tasklist
	@echo https://$(fqdn)/optimize
	@echo $(fqdn):443

# 8 public-zeebe-ingress : add an ingress for GRPC communication to zeebe-gateway
.PHONY: public-zeebe-ingress
public-zeebe-ingress: 
	cat $(root)/azure/include/public-zeebe-ingress.yaml | sed -E "s/MY_HOSTNAME/$(fqdn)/g;" | kubectl create -n $(namespace) -f -

# Optional: Run 'make config-keycloak' from camunda.mk to allow non-ssl connections to Keycloak

### <--- End of setup --->

# Remove nginx ingress and Camunda from cluster
.PHONY: clean-all
clean-all: clean-camunda clean-ingress clean-cert-manager
	rm -f $(chartValues)

include $(root)include/camunda.mk
include $(root)include/ingress-nginx.mk
include $(root)include/cert-manager.mk
include $(root)azure/include/aks.mk
include $(root)azure/include/fileshare.mk
# include $(root)include/zbctl.mk



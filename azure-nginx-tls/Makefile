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

# 0 Create kubernetes cluster. 
# Include ingress-azure from greenfiled\kubernetes-azure.mk not suitable, no aplication gatewya required here.
.PHONY: kube
kube:
	az group create --name $(resourceGroup) --location $(region)
	az aks create \
      --resource-group $(resourceGroup) \
      --name $(clusterName) \
      --node-vm-size $(machineType) \
      --node-count 1 \
      --vm-set-type VirtualMachineScaleSets \
      --enable-cluster-autoscaler \
      --min-count $(minSize) \
      --max-count $(maxSize) \
      --enable-managed-identity \
      --generate-ssh-keys
	kubectl config unset clusters.$(clusterName)
	kubectl config unset users.clusterUser_$(resourceGroup)_$(clusterName)
	az aks get-credentials --resource-group $(resourceGroup) --name $(clusterName)
	kubectl apply -f ./ssd-storageclass-azure.yaml

.PHONY: all
all: ingress-nginx camunda-values-nginx.yaml camunda config-keycloak ingress-nginx-routes external-urls

# 1 ingress-nginx from ingress-nginx.mk via include

# 2 Create camunda-values-nginx.yaml from ingress-mnginx.mk via include

# 3 camunda from camunda.mk via include

# 4 config-keycloak from camunda.mk via include

# 5 aply routes to ingress. Can't use ingress-azure via include as it expects a setup with aplpication gateway
.PHONY: ingress-nginx-routes
ingress-nginx-routes: ingress-ip-from-service
	@echo "Configuring ingress controller routes for: http://$(IP).nip.io" ;
	cat ingress-nginx.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -n ingress-nginx -f -

# 6 Show external URLs for web applications
.PHONY: external-urls
external-urls: ingress-ip-from-service
	@echo http://keycloak.$(IP).nip.io
	@echo http://identity.$(IP).nip.io
	@echo http://operate.$(IP).nip.io
	@echo http://optimize.$(IP).nip.io

# <--- End of setup --->

# Remove nginx ingress and Camunda from cluster
.PHONY: clean
clean: clean-ingress clean-camunda
	rm -f camunda-values-nginx.yaml




.PHONY: add-dnsLabel
add-dnsLabel: 
# $(eval publicIpId=$(shell az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$(IP)')].[id]" --output tsv))
# az network public-ip update --ids $(publicIpId) --dns-name $(dnsLabel)
# az network public-ip show --ids $(publicIpId) --query "[dnsSettings.fqdn]" --output tsv
	helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(dnsLabel)


.PHONY: add-tls
add-tls: 

.PHONY: install-certmgr
install-certmgr: 
# Label the ingress-basic namespace to disable resource validation
	kubectl label namespace ingress-basic cert-manager.io/disable-validation=true
# Add the Jetstack Helm repository
	helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
	helm repo update

# Install the cert-manager Helm chart
	helm install cert-manager jetstack/cert-manager \
	--namespace ingress-basic \
	--version $CERT_MANAGER_TAG \
	--set installCRDs=true \
	--set nodeSelector."kubernetes\.io/os"=linux \
	--set image.repository=$ACR_URL/$CERT_MANAGER_IMAGE_CONTROLLER \
	--set image.tag=$CERT_MANAGER_TAG \
	--set webhook.image.repository=$ACR_URL/$CERT_MANAGER_IMAGE_WEBHOOK \
	--set webhook.image.tag=$CERT_MANAGER_TAG \
	--set cainjector.image.repository=$ACR_URL/$CERT_MANAGER_IMAGE_CAINJECTOR \
	--set cainjector.image.tag=$CERT_MANAGER_TAG


include ../include/ingress-nginx.mk
include ../include/camunda.mk

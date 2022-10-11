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

.PHONY: all
all: ingress-nginx camunda-values-nginx.yaml camunda config-keycloak ingress-nginx-routes

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

.PHONY: ingress-nginx
ingress-nginx: ingress-ip-from-service
# -kubectl create namespace ingress-nginx
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx \
	--create-namespace \
	--namespace $(namespace) \
	--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

.PHONY: ingress-ip-from-service
ingress-ip-from-service:
	$(eval IP := $(shell kubectl --namespace camunda get services ingress-nginx-controller -o wide | awk 'NR!=1 {print $$4}'))
	@echo "Ingress controller will be configured to use address: http://$(IP).nip.io"

.PHONY: ingress-nginx-routes
ingress-nginx-routes: ingress-ip-from-service
	echo "Configuring ingress controller at: http://$(IP).nip.io" ;
	cat ingress-nginx.yaml | sed -E "s/([0-9]{1,3}\.){3}[0-9]{1,3}/$(IP)/g" | kubectl apply -n $(namespace) -f -

.PHONY: camunda-values-nginx.yaml
camunda-values-nginx.yaml: ingress-ip-from-service
	@echo configuring ingress for extewrnal IP: $(IP)
	sed "s/127.0.0.1/$(IP)/g;" ../ingress-nginx/camunda-values.yaml > ./camunda-values-nginx.yaml

# .PHONY: lb-ip-address
# lb-ip-address:
# 	$(eval IP := $(shell az network public-ip list -g $(nodeResourceGroup) -o tsv --query [0].ipAddress))
# 	@echo Load Balancer External IP address: $(IP)

# .PHONY: lb-routes
# lb-routes:
# 	az network lb outbound-rule list --resource-group $(nodeResourceGroup) --lb-name kubernetes -o table


.PHONY: clean
clean: clean-ingress-azure clean-camunda
	rm -f camunda-values-azure.yaml

.PHONY: external-urls
external-urls: ingress-ip-from-service
	@echo http://keycloak.$(IP).nip.io
	@echo http://identity.$(IP).nip.io
	@echo http://operate.$(IP).nip.io
	@echo http://optimize.$(IP).nip.io

include ../include/camunda.mk

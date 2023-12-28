.PHONY: create-resource-group
create-resource-group:
	az group create --name $(resourceGroup) --location $(region)

.PHONY: create-vnet
create-vnet:
	az network vnet create \
	  --name $(vnetName) \
	  --resource-group $(resourceGroup) \
	  --address-prefix $(addressPrefix) \
	  -o none
#	  --subnet-name $(subnetName) \
#	  --subnet-prefixes $(subnetPrefix)

.PHONY: create-node-subnet
create-node-subnet:
	az network vnet subnet create \
	  -g $(resourceGroup) \
	  --vnet-name $(vnetName) \
	  --name $(nodeSubnetName) \
	  --address-prefixes $(nodeSubnetPrefix) \
	  -o none

.PHONY: create-pod-subnet
create-pod-subnet:
	az network vnet subnet create \
	  -g $(resourceGroup) \
	  --vnet-name $(vnetName) \
	  --name $(podSubnetName) \
	  --address-prefixes $(podSubnetPrefix) \
	  -o none

.PHONY: create-vnet-peering
create-vnet-peering:
	$(eval result := $(shell az network vnet show --resource-group $(remoteResourceGroup) --name $(remoteVnetName) | jq -r '.id'))
	az network vnet peering create --name $(vnetPeeringName) \
 	  --remote-vnet $(result) \
 	  --resource-group $(resourceGroup) \
 	  --vnet-name $(vnetName) \
 	  --allow-forwarded-traffic true \
 	  --allow-vnet-access true

.PHONY: kube-aks
kube-aks:
	$(eval NodeSubnetResult := $(shell az network vnet subnet show --resource-group $(resourceGroup) --vnet-name $(vnetName) --name $(nodeSubnetName) | jq -r '.id'))
	$(eval PodSubnetResult := $(shell az network vnet subnet show --resource-group $(resourceGroup) --vnet-name $(vnetName) --name $(podSubnetName) | jq -r '.id'))
	az aks create \
	--resource-group $(resourceGroup) \
	 --name $(clusterName) \
	 --node-vm-size $(machineType) \
	 --node-count 1 \
	 --network-plugin azure \
	 --max-pods 250 \
	 --vnet-subnet-id $(NodeSubnetResult) \
	 --pod-subnet-id $(PodSubnetResult) \
	 --enable-cluster-autoscaler \
	 --min-count $(minSize) \
	 --max-count $(maxSize)
#	 --enable-managed-identity \
#	 --generate-ssh-keys
#	 --pod-cidr $(podCidr) \
#	 --service-cidr $(serviceCidr) \
#	 --dns-service-ip $(dnsServiceIp) \
#	 --network-plugin azure \
#	 --network-plugin-mode overlay

	kubectl config unset clusters.$(clusterName)
	kubectl config unset users.clusterUser_$(resourceGroup)_$(clusterName)
	az aks get-credentials --resource-group $(resourceGroup) --name $(clusterName)
	kubectl apply -f $(root)/azure/include/ssd-storageclass.yaml

.PHONY: kube-agic
kube-agic:
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
      -a ingress-appgw \
      --appgw-name $(gatewayName) \
      --appgw-subnet-cidr "10.225.0.0/16" \
      --generate-ssh-keys
	kubectl config unset clusters.$(clusterName)
	kubectl config unset users.clusterUser_$(resourceGroup)_$(clusterName)
	az aks get-credentials --resource-group $(resourceGroup) --name $(clusterName)
	kubectl apply -f $(root)/azure/include/ssd-storageclass.yaml

.PHONY: clean-kube-aks
clean-kube-aks: use-kube
	az aks delete -y -g $(resourceGroup) -n $(clusterName)
	az group delete -y --resource-group $(resourceGroup)

.PHONY: use-kube
use-kube:
	kubectl config unset clusters.$(clusterName)
	kubectl config unset users.clusterUser_$(resourceGroup)_$(clusterName)
	az aks get-credentials --resource-group $(resourceGroup) --name $(clusterName)

# TODO, in order for this to work, we'd need to first find NodeResourceGroup
# az aks show --resource-group dave-camunda-01-rg --name dave-camunda-01 --query nodeResourceGroup -o tsv
# Value will be something like: MC_dave-camunda-01-rg_dave-camunda-01_eastus
.PHONY: create-static-ip
create-static-ip:
	az network public-ip create --resource-group MC_dave-camunda-01-rg_dave-camunda-01_eastus --name $(clusterName)StaticIP --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv

# https://learn.microsoft.com/en-us/azure/dns/dns-getstarted-cli
.PHONY: dns-create-a-record
dns-create-a-record: ingress-ip-from-service
	az network dns record-set a add-record -g $(dnsZoneGroup) -z $(baseDomainName) -n $(dnsLabel) -a $(IP)
	az network dns record-set list -g $(dnsZoneGroup) -z $(baseDomainName)

.PHONY: dns-remove-a-record
dns-remove-a-record: ingress-ip-from-service
	az network dns record-set a remove-record -g $(dnsZoneGroup) -z $(baseDomainName) -n $(dnsLabel) -a $(IP)
	az network dns record-set list -g $(dnsZoneGroup) -z $(baseDomainName)

.PHONY: dns-test
dns-test:
	az network dns record-set ns show -g $(dnsZoneGroup) -z $(dnsZoneName) -n $(dnsLabel)

.PHONY: azure-ingress-nginx
azure-ingress-nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
	  --set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
	  --set controller.config.error-log-level="debug" \
	  --set controller.service.externalTrafficPolicy=Local \
	  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(dnsLabel)

.PHONY: ingress-annotate-staticip
ingress-annotate-staticip: ingress-ip-from-service
	kubectl -n $(namespace) annotate ingress camunda-camunda-platform controller.service.loadBalancerIP=$(IP)

.PHONY: create-clound-dns
create-cloud-dns: fqdn
	gcloud dns record-sets create $(fqdn) \
	  --rrdatas=$(IP) \
	  --ttl=30 \
	  --type=A \
	  --zone=$(dnsManagedZone)

.PHONY: delete-cloud-dns
delete-cloud-dns: fqdn
	gcloud dns record-sets delete $(fqdn) \
	  --type=A \
	  --zone=$(dnsManagedZone)

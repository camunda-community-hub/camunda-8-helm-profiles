.PHONY: kube-nginx
kube-nginx:
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

.PHONY: clean-kube
clean-kube: use-kube
	az aks delete -y -g $(resourceGroup) -n $(clusterName)
	az group delete -y --resource-group $(resourceGroup)

.PHONY: use-kube
use-kube:
	kubectl config unset clusters.$(clusterName)
	kubectl config unset users.clusterUser_$(resourceGroup)_$(clusterName)
	az aks get-credentials --resource-group $(resourceGroup) --name $(clusterName)

.PHONY: azure-dns-zone
azure-dns-zone:
	az network dns zone create -g $(resourceGroup) -n $(baseDomainName)

.PHONY: azure-dns-record
azure-dns-record:
	az network dns record-set a add-record -g $(resourceGroup) -z $(baseDomainName) -n $(subDomainName) -a $(IP)
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
	  --set controller.service.externalTrafficPolicy=Local;

.PHONY: ingress-annotate-staticip
ingress-annotate-staticip: ingress-ip-from-service
	kubectl -n $(namespace) annotate ingress camunda-camunda-platform controller.service.loadBalancerIP=$(IP)

.PHONY: annotate-ingress-tls
annotate-ingress-tls: ingress-remove-issuer
	kubectl -n $(namespace) annotate ingress camunda-camunda-platform cert-manager.io/cluster-issuer=letsencrypt
	make get-ingress

.PHONY: azure-nginx-dns-tls
azure-nginx-dns-tls:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	if [ -n "$(useAzureDomain)" ]; then \
	  helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(dnsLabel) \
	  --set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
	  --set controller.service.annotations."cert-manager.io/cluster-issuer"="$(clusterIssuer)" \
	  --set controller.config.error-log-level="debug"; \
	else \
	  helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	  --set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
	  --set controller.service.annotations."cert-manager.io/cluster-issuer"="$(clusterIssuer)" \
	  --set controller.config.error-log-level="debug"; \
	fi


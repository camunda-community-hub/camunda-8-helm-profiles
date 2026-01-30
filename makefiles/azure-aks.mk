.PHONY: kube-aks
kube-aks:
	az group create --name $(DEPLOYMENT_NAME)-rg --location $(REGION)
	az aks create \
      --resource-group $(DEPLOYMENT_NAME)-rg \
      --name $(DEPLOYMENT_NAME) \
      --node-vm-size $(MACHINE_TYPE) \
      --node-count 1 \
      --vm-set-type VirtualMachineScaleSets \
      --enable-cluster-autoscaler \
      --min-count $(MIN_SIZE) \
      --max-count $(MAX_SIZE) \
      --enable-managed-identity \
      --generate-ssh-keys
	kubectl config unset clusters.$(DEPLOYMENT_NAME)
	kubectl config unset users.clusterUser_$(DEPLOYMENT_NAME)-rg_$(DEPLOYMENT_NAME)
	az aks get-credentials --resource-group $(DEPLOYMENT_NAME)-rg --name $(DEPLOYMENT_NAME)
	kubectl apply -f $(root)/azure/include/ssd-storageclass.yaml

.PHONY: kube
kube: kube-aks

.PHONY: kube-agic
kube-agic:
	az group create --name $(DEPLOYMENT_NAME)-rg --location $(REGION)
	az aks create \
      --resource-group $(DEPLOYMENT_NAME)-rg \
      --name $(DEPLOYMENT_NAME) \
      --node-vm-size $(MACHINE_TYPE) \
      --node-count 1 \
      --vm-set-type VirtualMachineScaleSets \
      --enable-cluster-autoscaler \
      --min-count $(MIN_SIZE) \
      --max-count $(MAX_SIZE) \
      --enable-managed-identity \
      -a ingress-appgw \
      --appgw-name $(GATEWAY_NAME) \
      --appgw-subnet-cidr "10.225.0.0/16" \
      --generate-ssh-keys
	kubectl config unset clusters.$(DEPLOYMENT_NAME)
	kubectl config unset users.clusterUser_$(DEPLOYMENT_NAME)-rg_$(DEPLOYMENT_NAME)
	az aks get-credentials --resource-group $(DEPLOYMENT_NAME)-rg --name $(DEPLOYMENT_NAME)
	kubectl apply -f $(root)/azure/include/ssd-storageclass.yaml

.PHONY: clean-kube-aks
clean-kube-aks: use-kube
	az aks delete -y -g $(DEPLOYMENT_NAME)-rg -n $(DEPLOYMENT_NAME)
	az group delete -y --resource-group $(DEPLOYMENT_NAME)-rg

.PHONY: clean-kube
clean-kube: clean-kube-aks

.PHONY: use-kube
use-kube:
	kubectl config unset clusters.$(DEPLOYMENT_NAME)
	kubectl config unset users.clusterUser_$(DEPLOYMENT_NAME)-rg_$(DEPLOYMENT_NAME)
	az aks get-credentials --resource-group $(DEPLOYMENT_NAME)-rg --name $(DEPLOYMENT_NAME)

.PHONY: ingress-nginx-azure
ingress-nginx-azure:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
	  --set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
	  --set controller.config.error-log-level="debug" \
	  --set controller.service.externalTrafficPolicy=Local \
	  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"=$(DEPLOYMENT_NAME)

.PHONY: ingress-nginx
ingress-nginx: ingress-nginx-azure

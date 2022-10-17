# https://9to5tutorial.com/mount-an-azure-file-share-from-a-pod-on-an-aks-virtual-node-aci
# https://zimmergren.net/mount-an-azure-storage-file-share-to-deployments-in-azure-kubernetes-services-aks/
fsAccount ?= mystorage
fsRg ?= fileshare-rg
fsShare ?= aksshare
haha ?= ""

.PHONY: fileshare
fileshare:
	$(eval fsAccount := camStorage$(shell cat /dev/urandom | tr -dc 'a-z0-9' | fold -w $${1:-12} | head -n 1))
	@echo $(fsAccount)
	az group create -n $(fsRg) -l $(region)
	az storage account create -n $(fsAccount) -g $(fsRg) -l $(region) --sku Standard_LRS
#	$(eval fsConStr := $(shell az storage account show-connection-string -n $(fsAccount) -g $(fsRg) -o tsv))
#	az storage share create -n $(fsShare) --connection-string $(fsConStr)
#	$(eval fsKey := $(shell az storage account keys list --resource-group $(fsRg) --account-name $(fsAccount) --query "[0].value" -o tsv))
	@echo Storage account name: $(fsAccount)
	@echo Storage account key: $(fsKey)

.PHONY: clean-fileshare
clean-fileshare:
	az storage share delete -n $(fsAccount)
	az group delete -n $(fsRg) -l $(region)
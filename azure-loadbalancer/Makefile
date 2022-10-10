# Set these values to what you want for your specific environment
namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform

# These must be set to match resources that already exist inside an existing Azure Environment
resourceGroup ?= greenfield-group-01
nodeResourceGroup ?= greenfield-node-group-01
gatewayName ?= myApplicationGateway

chartValues ?= camunda-values-azure.yaml

.PHONY: all
all: lb-ip-address camunda-values-azure ingress-azure camunda

camunda-values-azure: lb-ip-address
	@echo configuring ingress for extewrnal IP: $(IP)
	sed "s/127.0.0.1/$(IP)/g;" ../ingress-nginx/camunda-values.yaml > ./camunda-values-azure.yaml

.PHONY: lb-ip-address
lb-ip-address:
	$(eval IP := $(shell az network public-ip list -g $(nodeResourceGroup) -o tsv --query [0].ipAddress))
	@echo Load Balancer External IP address: $(IP)

.PHONY: lb-routes
lb-routes:
	az network lb outbound-rule list --resource-group $(nodeResourceGroup) --lb-name kubernetes -o table


.PHONY: clean
clean: clean-ingress-azure clean-camunda
	rm -f camunda-values-azure.yaml

.PHONY: external-urls
external-urls: lb-ip-address
	@echo http://keycloak.$(IP).nip.io
	@echo http://identitiy.$(IP).nip.io
	@echo http://operate.$(IP).nip.io
	@echo http://optimize.$(IP).nip.io

include ../include/ingress-azure.mk
include ../include/camunda.mk

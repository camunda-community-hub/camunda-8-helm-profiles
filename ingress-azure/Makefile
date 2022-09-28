# Set these values to what you want for your specific environment
namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform

# These must be set to match resources that already exist inside an existing Azure Environment
nodeResourceGroup ?= greenfield-node-group-01
gatewayName ?= myApplicationGateway

chartValues ?= camunda-values-azure.yaml

.PHONY: all
all: ingress-azure camunda-values-azure.yaml camunda

.PHONY: clean
clean: clean-ingress-azure clean-camunda
	rm -f camunda-values-azure.yaml

include ../include/ingress-azure.mk
include ../include/camunda.mk

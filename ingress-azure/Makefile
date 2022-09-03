namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
chartValues ?= "camunda-values.yaml"

nodeResourceGroup ?= greenfield-node-group-01
gatewayName ?= myApplicationGateway

.PHONY: all
all: ingress-azure camunda

.PHONY: clean
clean: clean-ingress-azure clean-camunda

include ../include/ingress-azure.mk
include ../include/camunda.mk

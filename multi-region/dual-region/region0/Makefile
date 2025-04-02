.PHONY: all # install Camunda and broker services
all: install-camunda service-per-broker

.PHONY: clean # uninstall Camunda and broker services
clean: clean-service-per-broker uninstall-camunda

.PHONY: service-per-broker # generate service for each broker
service-per-broker:
	kubectl apply -f ../service-per-broker.yaml -n $(namespace)

.PHONY: clean-service-per-broker # delete service for each broker
clean-service-per-broker:
	-kubectl delete -f ../service-per-broker.yaml -n $(namespace)

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../..
else
    root ?= $(shell pwd)/../../..
endif

include config.mk
include $(root)/include/camunda.mk

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/..
else
    root ?= $(shell pwd)/..
endif

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

certName ?= camunda

.PHONY: all
all: create-custom-certs list-sans create-keystore

.PHONY: clean-certs
clean-certs: delete-custom-certs

include $(root)/tls/selfsigned/self-signed-cert.mk
include $(root)/tls/keystore/keystore.mk
include $(root)/tls/tls.mk

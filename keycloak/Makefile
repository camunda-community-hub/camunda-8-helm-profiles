# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

project ?= camunda-researchanddevelopment
region ?= us-east1-b # see: https://cloud.withgoogle.com/region-picker/
clusterName ?= CLUSTER_NAME

keycloakChartVersion ?= 13.0.2
keycloakVersion ?= 19.0.3

keycloakAdminUser ?= admin
keycloakBase64EncodedAdminPassword ?= WTg1a2hvYklyYg==
keycloakBase64EncodedManagementPassword ?= NEtHclRnbTJjWg==
keycloakContextPath ?= /
keycloakHostName ?= KEYCLOAK_HOSTNAME

# Azure provides temporary dns names such as:  MY_DOMAIN_NAME.region.cloudapp.azure.com
# However GCP does not. DNS names will be configured using https://nip.io
# dnsLabel ?= MY_DOMAIN_NAME
machineType ?= n1-standard-16
minSize ?= 1
maxSize ?= 6
certEmail ?= YOUR_EMAIL@yourdomain.com


# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../..
else
    root ?= $(shell pwd)/../..
endif

namespace ?= keycloak

.PHONY: all
all: cert-manager letsencrypt-staging ingress-nginx-tls create-namespace-keycloak create-secret-keycloak install-keycloak

.PHONY: clean
clean: clean-keycloak


include $(root)/keycloak/keycloak.mk
include $(root)/include/cert-manager.mk
include $(root)/include/ingress-nginx.mk

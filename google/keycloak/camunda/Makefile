# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

project ?= camunda-researchanddevelopment
region ?= us-east1-b # see: https://cloud.withgoogle.com/region-picker/
clusterName ?= CLUSTER_NAME

# Set the following parameters to point to an existing Keycloak server
keycloakProtocol ?= https
keycloakHostname ?= KEYCLOAK_HOSTNAME
keycloakPort ?= 443
keycloakContextPath ?= /
keycloakBase64EncodedAdminPassword ?= WTg1a2hvYklyYg==
keycloakBase64EncodedManagementPassword ?= NEtHclRnbTJjWg==

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
    root ?= $(CURDIR)/../../..
else
    root ?= $(shell pwd)/../../..
endif

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform

# This file will be generated by make targets
#chartValues ?= camunda-values-ext-keycloak.yaml
chartValues ?= camunda-values-ext-keycloak.yaml

.PHONY: all
all: cert-manager letsencrypt-staging ingress-nginx-tls namespace create-secret-keycloak cacerts-staging camunda-values-ext-keycloak-ip.yaml camunda annotate-ingress-tls external-urls

# 0 kube from cluster.mk: Create Kubernetes cluster. (No aplication gateway required)
.PHONY: kube
kube: kube-gke metrics

# 1 cert-manager from cert-manager.mk: create certificate manager for tls

# 2 letsencrypt-staging/-prod from cert-manager.mk: create letsencrypt cert issuer

# 3 create nginx ingress controller with dns and tls

# 4 create secrets.yaml with k8s secret that contains Keycloak Admin and Management passwords

# 5 create camunda-values-ext-keycloak.yaml with external ip from ingress controller's Loadbalancer and keycloak params
camunda-values-ext-keycloak-ip.yaml: fqdn
	sed -e "s|YOUR_HOSTNAME|$(fqdn)|g;" \
	-e "s|KEYCLOAK_PROTOCOL|$(keycloakProtocol)|g;" \
	-e "s|KEYCLOAK_HOSTNAME|$(keycloakHostname)|g;" \
	-e "s|KEYCLOAK_PORT|$(keycloakPort)|g;" \
	-e "s|KEYCLOAK_CONTEXT_PATH|$(keycloakContextPath)|g;" \
	-e "s|//realms|/realms|g;" \
	$(root)/keycloak/camunda-values-ext-keycloak.tpl.yaml > ./camunda-values-ext-keycloak.yaml

# 6 helm install camunda from camunda.mk with own tls config, combined ingress, and external keycloak

# 7 annotate-ingress-tls from cert-manager.mk: add cluster-issuer annotation to nginx

# 8 Show external URLs
.PHONY: external-urls
external-urls: ingress-ip-from-service
	@echo https://$(IP).nip.io/auth
	@echo https://$(IP).nip.io/identity
	@echo https://$(IP).nip.io/operate
	@echo https://$(IP).nip.io/tasklist
	@echo https://$(IP).nip.io/optimize
	@echo $(IP).nip.io:443

.PHONY: clean
clean: clean-camunda clean-ingress clean-cert-manager
	rm -f $(chartValues)

.PHONY: clean-kube
clean-kube: clean-metrics clean-kube-gke

include $(root)/include/camunda.mk
include $(root)/include/ingress-nginx.mk
include $(root)/include/cert-manager.mk
include $(root)/google/include/kubernetes-gke.mk
include $(root)/metrics/metrics.mk
include $(root)/keycloak/keycloak.mk


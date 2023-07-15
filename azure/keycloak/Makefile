# ------------------------------------
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

region ?= eastus
clusterName ?= dave-keycloak-01
resourceGroup ?= dave-keycloak-01-rg

# Configure the fully qualified domain name
# A fully qualified domain name is built by appending `dnsLabel` together with `baseDomainName`.
# By default, in Azure, we can use the `cloudapp.azure.com` base domain.
#baseDomainName ?= $(region).cloudapp.azure.com
# Another option is to replace baseDomainName with your own domain name
baseDomainName ?= upgradingdave.com
# Yet another option option is to use `nip.io`
#baseDomainName ?= nip.io

# Replace `MY_DNS_LABEL`. For example, if you set `dnsLabel` to `camunda`, then the fqdn will be `camunda.mydomain.com`
dnsLabel ?= kc

machineType ?= Standard_A8_v2
minSize ?= 1
maxSize ?= 6
certEmail ?= david.paroulek@camunda.com

keycloakChartVersion ?= 13.0.2
keycloakVersion ?= 19.0.3

keycloakAdminUser ?= admin
keycloakBase64EncodedAdminPassword ?= WTg1a2hvYklyYg==
keycloakBase64EncodedManagementPassword ?= NEtHclRnbTJjWg==
keycloakContextPath ?= /

# ------------------------------------
# The following variables should not be changed except for advanced use cases
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../..
else
    root ?= $(shell pwd)/../..
endif

# Camunda components will be installed into the following Kubernetes namespace
namespace ?= keycloak


.PHONY: all
all: cert-manager letsencrypt-staging ingress-nginx-tls create-namespace-keycloak create-secret-keycloak keycloak-values-ip install-keycloak

# 0 kube from cluster.mk: Create Kubernetes cluster.
.PHONY: kube
kube: kube-aks

# 1 cert-manager from cert-manager.mk: create certificate manager for tls

# 2 letsencrypt-staging/-prod from cert-manager.mk: create letsencrypt cert issuer

# 3 create nginx ingress controller with dns and tls

# 4 create keycloak namespace

# 5 create keycloak secret (this will be reused when installing camunda)

# 6 create keycloak values (by default uses `keycloak-values-ip`. `keycloak-values-hostname` is also available)

# 7 helm install keycloak using `keycloak-values.yaml`

.PHONY: clean
clean: clean-keycloak

.PHONY: clean-kube
clean-kube: clean-keycloak clean-kube-aks

include $(root)/keycloak/keycloak.mk
include $(root)/include/cert-manager.mk
include $(root)/include/ingress-nginx.mk
include $(root)/azure/include/aks.mk

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
# Azure provides temporary dns names such as:  MY_DOMAIN_NAME.region.cloudapp.azure.com
# However GCP does not. DNS names will be configured using https://nip.io
# To use a custom hostname, uncomment the following,
# and change to use `keycloak-values-hostname` instead of `keycloak-values-ip`
# keycloakHostName ?= KEYCLOAK_HOSTNAME

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
all: cert-manager letsencrypt-staging ingress-nginx-tls create-namespace-keycloak create-secret-keycloak keycloak-values-ip install-keycloak

# 0 kube from cluster.mk: Create Kubernetes cluster.
.PHONY: kube
kube: kube-gke

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
clean-kube: clean-kube-gke


include $(root)/keycloak/keycloak.mk
include $(root)/include/cert-manager.mk
include $(root)/include/ingress-nginx.mk

include $(root)/google/include/kubernetes-gke.mk

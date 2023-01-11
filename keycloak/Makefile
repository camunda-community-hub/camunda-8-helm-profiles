# ------------------------------------
# The following variables should not be changed except for advanced use cases

root ?= $(shell pwd)/..

keycloakChartVersion ?= 13.0.2
keycloakVersion ?= 19.0.3
keycloakNamespace ?= keycloak
keycloakAdminUser ?= admin
keycloakBase64EncodedAdminPassword ?= WTg1a2hvYklyYg==
keycloakBase64EncodedManagementPassword ?= NEtHclRnbTJjWg==
keycloakContextPath ?= /
keycloakHostName ?= YOUR_KEYCLOAK_HOSTNAME

.PHONY: all
all: cert-manager letsencrypt-staging ingress-nginx-tls create-namespace-keycloak create-secret-keycloak install-keycloak

.PHONY: clean
clean: clean-keycloak


include $(root)/keycloak/keycloak.mk
include $(root)/include/cert-manager.mk
include $(root)/include/ingress-nginx.mk

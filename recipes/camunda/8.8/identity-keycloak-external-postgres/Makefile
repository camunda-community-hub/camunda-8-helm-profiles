# Determine the root directory
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../../..
else
    root ?= $(shell pwd)/../../../..
endif

# Create a local config.mk file in the root directory of this project
#  to override variables for your specific environment
-include $(root)/config.mk

#--------------------------------
# The following values will be used for any variables not set inside the config.mk

DEPLOYMENT_NAME ?= mydeployment

# Aurora Postgresql
POSTGRES_MASTER_USERNAME ?= postgres
POSTGRES_MASTER_PASSWORD ?= CHANGEME

POSTGRES_KEYCLOAK_DB ?= bitnami_keycloak
POSTGRES_KEYCLOAK_USERNAME ?= bn_keycloak

POSTGRES_IDENTITY_DB ?= identity
POSTGRES_IDENTITY_USERNAME ?= identity

# Camunda installation
CAMUNDA_NAMESPACE ?= camunda
CAMUNDA_RELEASE_NAME ?= camunda
CAMUNDA_CHART ?= camunda/camunda-platform

CAMUNDA_HELM_CHART_VERSION ?= 13.4.1
CAMUNDA_VERSION ?= 8.8.9

CAMUNDA_HELM_VALUES ?= \
  $(root)/camunda-values.yaml.d/8.8/disable-all.yaml \
  $(root)/camunda-values.yaml.d/8.8/elastic-enabled.yaml \
  $(root)/camunda-values.yaml.d/8.8/identity-keycloak-external-postgres.yaml \
  $(root)/camunda-values.yaml.d/8.8/connectors-enabled.yaml \
  $(root)/camunda-values.yaml.d/8.8/connectors-oidc.yaml \
  $(root)/camunda-values.yaml.d/8.8/orchestration-enabled.yaml \
  $(root)/camunda-values.yaml.d/8.8/orchestration-oidc.yaml

DEFAULT_PASSWORD ?= demo

CAMUNDA_CLUSTER_SIZE ?= 1
CAMUNDA_REPLICATION_FACTOR ?= 1
CAMUNDA_PARTITION_COUNT ?= 1

# Networking
IDENTITY_EXT_URL ?= http://localhost:8084
KEYCLOAK_EXT_URL ?= http://localhost:18080
ORCHESTRATION_EXT_URL ?= http://localhost:8080

# Keycloak
KEYCLOAK_ADMIN_USERNAME ?= keycloak_admin
KEYCLOAK_REALM ?= camunda-platform
KEYCLOAK_EXT_URL ?= http://localhost:18080
#--------------------------------

.PHONY: all
all: camunda-values.yaml create-camunda-credentials camunda

.PHONY: clean
clean: clean-camunda

include $(root)/makefiles/aws-eks.mk
include $(root)/makefiles/aws-aurora.mk
include $(root)/makefiles/camunda.mk

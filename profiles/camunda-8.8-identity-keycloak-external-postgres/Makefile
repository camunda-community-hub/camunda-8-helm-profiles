# Determine the root directory
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../..
else
    root ?= $(shell pwd)/../..
endif

# Create a local config.mk file to override variables for your specific environment
-include config.mk

#--------------------------------
# The following values will be used for any variables not set inside the config.mk

DEPLOYMENT_NAME ?= mydeployment
# Cloud environment and K8s cluster
REGION ?= ca-central-1
ZONES ?= ['ca-central-1a', 'ca-central-1b']

MACHINE_TYPE ?= c6i.4xlarge
CLUSTER_VERSION ?= 1.34
VOLUME_SIZE ?= 100

DESIRED_SIZE ?= 3
MIN_SIZE ?= 1
MAX_SIZE ?= 6

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
  $(root)/camunda-values.yaml.d/8.8-disable-all.yaml \
  $(root)/camunda-values.yaml.d/8.8-identity-keycloak-external-postgres.yaml

DEFAULT_PASSWORD ?= demo

# Networking
IDENTITY_EXT_URL ?= http://localhost:8084
KEYCLOAK_EXT_URL ?= http://localhost:18080

# Keycloak
KEYCLOAK_ADMIN_USERNAME ?= keycloak_admin
KEYCLOAK_REALM ?= camunda-platform
KEYCLOAK_EXT_URL ?= http://localhost:18080
#--------------------------------

.PHONY: all
all: kube setup-aurora-db camunda-values.yaml create-camunda-credentials camunda

.PHONY: setup-aurora-db
setup-aurora-db: create-aurora-db allow-eks-to-rds test-aurora-from-eks allow-local-to-rds test-aurora-from-local setup-keycloak-db
	@echo "Aurora DB and Keycloak database setup complete."

.PHONY: clean
clean: clean-camunda destroy-aurora-db clean-kube-aws

include $(root)/makefiles/aws-eks.mk
include $(root)/makefiles/aws-aurora.mk
include $(root)/makefiles/camunda-install.mk

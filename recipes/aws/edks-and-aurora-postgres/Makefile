# Determine the root directory
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../..
else
    root ?= $(shell pwd)/../../..
endif

# Create a local config.mk file in the root directory of this project
#  to override variables for your specific environment
-include $(root)/config.mk

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

POSTGRES_MODELER_DB ?= modeler
POSTGRES_MODELER_USERNAME ?= modeler

DEFAULT_PASSWORD ?= demo

#--------------------------------

.PHONY: all
all: kube setup-aurora-db

.PHONY: setup-aurora-db
setup-aurora-db: create-aurora-db allow-eks-to-rds test-aurora-from-eks allow-local-to-rds test-aurora-from-local setup-all-dbs
	@echo "Aurora DB and Camunda database setup complete."

.PHONY: clean
clean: destroy-aurora-db clean-kube-aws

include $(root)/makefiles/aws-eks.mk
include $(root)/makefiles/aws-aurora.mk
include $(root)/makefiles/camunda.mk

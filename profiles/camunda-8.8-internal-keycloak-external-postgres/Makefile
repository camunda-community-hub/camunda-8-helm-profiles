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

# EKS cluster
REGION ?= us-east-1
ZONES ?= ['us-east-1a', 'us-east-1b']

MACHINE_TYPE ?= c6i.4xlarge
CLUSTER_VERSION ?= 1.34
VOLUME_SIZE ?= 100

DESIRED_SIZE ?= 3
MIN_SIZE ?= 1
MAX_SIZE ?= 6

# Aurora Postgresql
POSTGRES_MASTER_USERNAME ?= postgres
POSTGRES_MASTER_PASSWORD ?= CHANGEME

#--------------------------------

.PHONY: all
all: kube create-aurora-db allow-eks-to-rds test-aurora-from-edks  camunda-values.yaml create-camunda-credentials camunda

.PHONY: clean
clean: clean-camunda destroy-aurora-db clean-kube-aws

include $(root)/makefiles/aws-eks.mk
include $(root)/makefiles/aws-aurora.mk
include $(root)/makefiles/camunda-install.mk

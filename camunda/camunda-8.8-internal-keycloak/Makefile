# ------------------------------------
# Set variables inside a .env file to customize for your specific environment
-include .env

# The following values will be used for any variables not set inside the environment

DEPLOYMENT_NAME ?= mydeployment
REGION ?= us-east-1
ZONES ?= ['us-east-1a', 'us-east-1b']

MACHINE_TYPE ?= c6i.4xlarge
CLUSTER_VERSION ?= 1.34
VOLUME_SIZE ?= 100

DESIRED_SIZE ?= 3
MIN_SIZE ?= 1
MAX_SIZE ?= 6
CERT_EMAIL ?= YOUR_EMAIL@camunda.com

# ------------------------------------
# The following variables should not be changed except for advanced use cases
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../..
else
    root ?= $(shell pwd)/../..
endif

.PHONY: all
all: camunda-values.yaml create-camunda-credentials camunda

.PHONY: clean
clean: clean-kube-aws

include $(root)/camunda/include/camunda-install.mk

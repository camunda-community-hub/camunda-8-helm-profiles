# ------------------------------------
# Set variables inside a .env file to customize for your specific environment
-include .env

# The following values will be used for any variables not set inside the environment

DEPLOYMENT_NAME ?= mydeployment
REGION ?= us-east-1
ZONES ?= ['us-east-1a', 'us-east-1b']

MACHINE_TYPE ?= c6i.4xlarge
CIDR_BLOCK ?= 10.0.0.0/16

# ------------------------------------
# The following variables should not be changed except for advanced use cases
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../..
else
    root ?= $(shell pwd)/../..
endif

.PHONY: all
all: create-vpc-01

.PHONY: clean
clean:
	$(MAKE) -C $(root)/aws/vpc delete-vpc VPC_NAME=$(DEPLOYMENT_NAME)-vpc-01

include $(root)/aws/include/aws-vpc.mk

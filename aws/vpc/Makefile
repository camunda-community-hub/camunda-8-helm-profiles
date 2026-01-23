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
all: create-vpc-01 create-subnet-01

.PHONY: create-vpc-01
create-vpc-01:
	$(MAKE) -C $(root)/aws/vpc create-vpc VPC_NAME=$(DEPLOYMENT_NAME)-vpc-01 REGION=$(REGION) CIDR_BLOCK=$(CIDR_BLOCK)

.PHONY: create-subnet-01
create-subnet-01:
	$(eval AVAILABILITY_ZONE := $(shell echo $(ZONES) | sed "s/[][ ']//g" | cut -d, -f1))
	$(eval SUBNET_CIDR_BLOCK := $(shell echo $(CIDR_BLOCK) | cut -d. -f1-2).1.0/24)
	$(MAKE) -C $(root)/aws/vpc create-subnet VPC_NAME=$(DEPLOYMENT_NAME)-vpc-01 SUBNET_NAME=$(DEPLOYMENT_NAME)-subnet-01 SUBNET_CIDR_BLOCK=$(SUBNET_CIDR_BLOCK) AVAILABILITY_ZONE=$(AVAILABILITY_ZONE)

.PHONY: clean
clean:
	$(MAKE) -C $(root)/aws/vpc delete-subnet SUBNET_NAME=$(DEPLOYMENT_NAME)-subnet-01
	$(MAKE) -C $(root)/aws/vpc delete-vpc VPC_NAME=$(DEPLOYMENT_NAME)-vpc-01

include $(root)/aws/include/aws-vpc.mk

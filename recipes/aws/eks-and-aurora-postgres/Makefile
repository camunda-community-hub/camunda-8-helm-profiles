# Determine the root directory
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../../..
else
    root ?= $(shell pwd)/../../..
endif

# Create a config.mk file in the root directory of this project to override defaults included below
-include $(root)/config.mk

# Theses are the default values used by this recipe
include ./config.mk

.PHONY: all
all: kube setup-aurora-db

.PHONY: setup-aurora-db
setup-aurora-db: create-aurora-db allow-eks-to-rds test-aurora-from-eks allow-local-to-rds test-aurora-from-local setup-all-dbs
	@echo "Aurora DB and Camunda database setup complete."

.PHONY: clean
clean: destroy-aurora-db clean-kube

include $(root)/makefiles/aws-eks.mk
include $(root)/makefiles/aws-aurora.mk
include $(root)/makefiles/camunda.mk

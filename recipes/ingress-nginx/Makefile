# Determine the root directory
ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../..
else
    root ?= $(shell pwd)/../..
endif

# Create a config.mk file in the root directory of this project to override defaults included below
-include $(root)/config.mk

# Theses are the default values used by this recipe
include ./config.mk

.PHONY: all
all: kube

.PHONY: clean
clean: clean-kube

include $(root)/makefiles/google-gke.mk
include $(root)/makefiles/ingress-nginx.mk
include $(root)/makefiles/letsencrypt.mk

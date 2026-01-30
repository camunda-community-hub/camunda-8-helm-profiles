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
all: kube

.PHONY: clean
clean: clean-ingress clean-metrics clean-kube

.PHONY: setup-metrics
setup-metrics: metrics

.PHONY: setup-nginx-ingress
setup-nginx-ingress: ingress-nginx cert-manager letsencrypt-prod

include $(root)/makefiles/azure-common.mk
include $(root)/makefiles/azure-aks.mk
include $(root)/makefiles/letsencrypt.mk
include $(root)/makefiles/ingress-nginx.mk
include $(root)/makefiles/metrics.mk

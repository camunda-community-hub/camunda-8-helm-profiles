ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/..
else
    root ?= $(shell pwd)/..
endif

.PHONY: all
all: camunda-values-openshift.yaml camunda

include $(root)/openshift/openshift.mk

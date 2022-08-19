namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
# Chart values files
# TODO: test passing in a list
chartValues ?= "camunda-values.yaml" # TODO document composition of profiles, e.g. chartValues ?= "camunda-values.yaml ../development/camunda-values.yaml"


.PHONY: all
all: ingress camunda

.PHONY: clean
clean: clean-camunda clean-ingress

include ../include/ingress-nginx.mk
include ../include/camunda.mk

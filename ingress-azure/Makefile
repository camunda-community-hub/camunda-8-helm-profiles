namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
# Chart values files
# TODO: test passing in a list
chartValues ?= "camunda-values.yaml" # TODO document composition of profiles ../debug/camunda-values.yaml"


.PHONY: all
all: ingress camunda

.PHONY: clean
clean: clean-ingress clean-camunda

include ../include/ingress-azure.mk
include ../include/camunda.mk

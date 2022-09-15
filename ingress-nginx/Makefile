namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform

chartValues ?= "camunda-values.yaml"


.PHONY: all
all: ingress camunda

.PHONY: clean
clean: clean-camunda clean-ingress
	rm -f camunda-values-nginx.yaml

include ../include/ingress-nginx.mk
include ../include/camunda.mk

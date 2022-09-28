# Set these values to what you want for your specific environment
namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform

chartValues ?= "camunda-values-aws.yaml"

.PHONY: all
all: ingress-nginx await-elb camunda-values-aws.yaml camunda

.PHONY: clean
clean: clean-ingress clean-camunda
	rm -f camunda-values-aws.yaml

include ../include/ingress-nginx.mk
include ./ingress-aws.mk
include ../include/camunda.mk

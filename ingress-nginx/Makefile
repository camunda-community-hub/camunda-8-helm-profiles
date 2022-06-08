namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform

.PHONY: all
all: ingress camunda

.PHONY: clean
clean: clean-camunda clean-ingress

include ../include/ingress-nginx.mk
include ../include/camunda.mk
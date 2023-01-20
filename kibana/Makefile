root ?= $(shell pwd)/..

namespace ?= camunda
# Make sure to match the same version of elasticsearch
kibanaVersion ?= 7.17.3

.PHONY: all
all: install-kibana

.PHONY: clean
clean: clean-kibana

include $(root)/kibana/kibana.mk
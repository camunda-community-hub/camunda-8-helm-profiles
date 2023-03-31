
# ------------------------------------
# The following variables should not be changed except for advanced use cases

ifeq ($(OS),Windows_NT)
    root ?= $(CURDIR)/../..
else
    root ?= $(shell pwd)/../..
endif

dockerComposeFile ?= $(root)/docker/gateway-with-3-brokers/docker-compose.yaml

.PHONY: all
all: docker-compose-up

.PHONY: status
status: docker-compose-ps

# curl -f http://localhost:9600/health

.PHONY: clean
clean: docker-compose-down

include $(root)/docker/docker.mk


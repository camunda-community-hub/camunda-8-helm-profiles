
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

.PHONY: health
health:
	docker inspect gateway-with-3-brokers-broker-1-1 | jq ".[].State.Health.Status"
	docker inspect gateway-with-3-brokers-broker-2-1 | jq ".[].State.Health.Status"
	docker inspect gateway-with-3-brokers-broker-3-1 | jq ".[].State.Health.Status"
	docker inspect gateway-with-3-brokers-gateway-1 | jq ".[].State.Health.Status"

# curl -f http://localhost:9600/health

.PHONY: clean
clean: docker-compose-down

include $(root)/docker/docker.mk


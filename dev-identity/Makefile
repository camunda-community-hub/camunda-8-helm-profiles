namespace ?= camunda
release ?= camunda
chart ?= camunda/camunda-platform
chartValues ?= camunda-values.yaml

.PHONY: all
all: camunda

.PHONY: clean
clean: clean-camunda

.PHONY: ports
ports:
	-kubectl port-forward svc/$(release)-zeebe-gateway 26500:26500 -n $(namespace) &
	-kubectl port-forward svc/$(release)-keycloak 18080:80 -n $(namespace) &
	-kubectl port-forward svc/$(release)-identity 8080:80 -n $(namespace) &
	-kubectl port-forward svc/$(release)-operate 8081:80 -n $(namespace) &
	-kubectl port-forward svc/$(release)-tasklist 8082:80 -n $(namespace) &
	-ps -f | grep 'kubectl' | grep 'port-forward' | awk '{print $$10 " " $$11}'

# add if Optimize is enabled
# -kubectl port-forward svc/$(release)-optimize 8083:80 -n $(namespace) &

.PHONY: noforward
noforward:
	-kill $$(ps -o pid -o cmd | awk '$$3 == "port-forward" {print $$1}')

include ../include/camunda.mk
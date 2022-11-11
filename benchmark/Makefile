# Camunda components will be installed into the following Kubernetes namespace
export namespace ?= camunda
# Helm release name
export release ?= camunda
# Helm chart coordinates for Camunda
export chart ?= camunda/camunda-platform

# This file is created during the make call which runs inside `$(helmProfilesDir)/ingress-aws`
export chartValues ?= "$(root)/benchmark/camunda-values-benchmark.yaml"


.PHONY: all
all: camunda await-zeebe deploy-models rebalance-partitions benchmark

.PHONY: chaos-all
chaos-all: all chaosmesh

.PHONY: rebalance-partitions
rebalance-partitions:
	kubectl port-forward --namespace camunda $(kubectl get pod --namespace camunda --selector="app=camunda-platform,app.kubernetes.io/component=zeebe-gateway,app.kubernetes.io/instance=camunda,app.kubernetes.io/managed-by=Helm,app.kubernetes.io/name=zeebe-gateway,app.kubernetes.io/part-of=camunda-platform" --output jsonpath='{.items[0].metadata.name}') 5432:9600 &
	curl -X POST http://localhost:5432/actuator/rebalance/
	sleep 10
	pkill -f "port-forward"

.PHONY: clean
clean: clean-benchmark clean-camunda


include $(root)/benchmark/benchmark.mk
include $(root)/benchmark/chaosmesh.mk
include $(root)/include/camunda.mk

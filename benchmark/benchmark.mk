
.PHONY: benchmark
benchmark: namespace
	kubectl create configmap payload --from-file=$(root)/benchmark/payload.json -n $(namespace)
	kubectl apply -f $(root)/benchmark/benchmark.yaml         -n $(namespace)

.PHONY: clean-benchmark
clean-benchmark:
	-kubectl delete -f $(root)/benchmark/benchmark.yaml -n $(namespace)
	-kubectl delete configmap payload -n $(namespace)

.PHONY: logs-benchmark
logs-benchmark:
	kubectl logs -f -l app=benchmark -n $(namespace)


.PHONY: deploy-models
deploy-models:
	kubectl create configmap models --from-file=$(root)/benchmark/BenchmarkProcess.bpmn     -n $(namespace)
	kubectl apply -f $(root)/benchmark/zbctl-deploy-job.yaml                                -n $(namespace)
	kubectl wait --for=condition=complete job/zbctl-deploy --timeout=300s -n $(namespace)
	kubectl delete configmap models                                       -n $(namespace)
	kubectl delete -f $(root)/benchmark/zbctl-deploy-job.yaml                               -n $(namespace)

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

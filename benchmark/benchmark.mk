
.PHONY: deploy-models
deploy-models:
	kubectl create configmap models --from-file=BenchmarkProcess.bpmn     -n $(namespace)
	kubectl apply -f zbctl-deploy-job.yaml                                -n $(namespace)
	kubectl wait --for=condition=complete job/zbctl-deploy --timeout=300s -n $(namespace)
	kubectl delete configmap models                                       -n $(namespace)
	kubectl delete -f zbctl-deploy-job.yaml                               -n $(namespace)

.PHONY: benchmark
benchmark: namespace
	kubectl create configmap payload --from-file=payload.json -n $(namespace)
	kubectl apply -f benchmark.yaml                           -n $(namespace)

.PHONY: clean-benchmark
clean-benchmark:
	-kubectl delete -f benchmark.yaml -n $(namespace)
	-kubectl delete configmap payload -n $(namespace)
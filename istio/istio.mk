.PHONY: istio-install-create
istio-install-create:
	cat $(root)/include/rebalance-leader-job.tpl.yaml | sed -E "s/RELEASE_NAME/$(release)/g" | kubectl apply -n $(namespace) -f -
	-kubectl wait --for=condition=complete job/leader-balancer --timeout=20s       -n $(namespace)


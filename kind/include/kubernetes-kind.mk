.PHONY: kube-kind
kube-kind:
	kind create cluster --config=$(root)/kind/include/config.yaml
	kubectl apply -f $(root)/kind/include/ssd-storageclass-kind.yaml

.PHONY: clean-kube-kind
clean-kube-kind: use-kube
	kind delete cluster --name camunda-kind-cluster

.PHONY: use-kube
use-kube:
	kubectl config use-context kind-camunda-kind-cluster

.PHONY: urls
urls:
	@echo "A cluster management url is not available on Kind"

.PHONY: ingress-nginx-kind
ingress-nginx-kind:
	# helm install -f $(root)/kind/include/nginx_ingress_values.yaml ingress-nginx oci://ghcr.io/nginxinc/charts/nginx-ingress --version 0.18.0
	kubectl apply -f $(root)/kind/include/deploy-ingress.yml
	kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=90s
#	kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

.PHONY: clean-ingress-kind
clean-ingress-kind:
	-kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	-kubectl delete namespace ingress-nginx

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
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission

.PHONY: clean-ingress
clean-ingress:
	helm --namespace ingress-nginx uninstall ingress-nginx
	kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	kubectl delete namespace ingress-nginx

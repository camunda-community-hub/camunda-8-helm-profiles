.PHONY: ingress-kind
ingress-kind: ingress-nginx-kind

.PHONY: ingress-nginx-kind
ingress-nginx-kind:
	-kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

.PHONY: clean-ingress
clean-ingress:
	-helm --namespace ingress-nginx uninstall ingress-nginx
	-kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	-kubectl delete namespace ingress-nginx

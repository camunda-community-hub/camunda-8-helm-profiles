.PHONY: istio-keycloak
istio-keycloak:
	cat $(root)/istio/keycloak.yaml | sed -e "s/RELEASE/$(release)/g" -e "s/HOSTNAME/keycloak.$(baseDomainName)/g" | kubectl apply -n $(namespace) -f -

.PHONY: istio-install
istio-install:
	helm repo add istio https://istio-release.storage.googleapis.com/charts
	helm repo update
	kubectl create namespace istio-system
	helm install istio-base istio/base -n istio-system --set defaultRevision=default
	helm install istiod istio/istiod -n istio-system --wait
	kubectl create namespace istio-ingress
	helm install istio-ingressgateway istio/gateway -n istio-ingress



# kubectl label namespace camunda istio-injection=enabled --overwrite
# kubectl logs camunda-keycloak-0 -c istio-proxy -n camunda


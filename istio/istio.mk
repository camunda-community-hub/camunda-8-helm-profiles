
.PHONY: istio-install
istio-install:
	istioctl install --set profile=demo -y # I don't know why profile=demo works, but the default profile doesn't work? it might have to do with egress?

.PHONY: istio-external-url
istio-external-url:
	kubectl get svc istio-ingressgateway -n istio-system

.PHONY: istio-label-ns
istio-label-ns: namespace
	kubectl label namespace $(namespace) istio-injection=enabled

.PHONY: istio-gateway
istio-gateway:
	cat $(root)/istio/gateway.tpl.yaml | sed -e "s/RELEASE/$(release)/g" | kubectl apply -n $(namespace) -f -

.PHONY: istio-tasklist
istio-tasklist:
	cat $(root)/istio/tasklist.tpl.yaml | sed -e "s/RELEASE/$(release)/g" | kubectl apply -n $(namespace) -f -

.PHONY: istio-operate
istio-operate:
	cat $(root)/istio/operate.tpl.yaml | sed -e "s/RELEASE/$(release)/g" | kubectl apply -n $(namespace) -f -

.PHONY: istio-keycloak
istio-keycloak:
	cat $(root)/istio/keycloak.tpl.yaml | sed -e "s/RELEASE/$(release)/g" | kubectl apply -n $(namespace) -f -

.PHONY: istio-virtual-services
istio-virtual-services: istio-keycloak istio-operate istio-tasklist






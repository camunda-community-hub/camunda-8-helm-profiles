# usage: make <target>
# example: make install-istio

install-istio:
	istioctl install --set profile=ambient --set values.global.platform=gke --skip-confirmation
	kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
	

uninstall-istio:
	istioctl uninstall -y --purge
	kubectl delete namespace istio-system

.PHONY: istio-destination-rule deploy-waypoint
istio-destination-rule:
	kubectl apply -f camunda-zeebe-gateway-grpc.yml
	kubectl apply -f istio-destination-rule-gateway.yaml

deploy-waypoint:
	kubectl apply -f istio-waypoint-defaults.yaml
	kubectl apply -f istio-waypoint.yaml
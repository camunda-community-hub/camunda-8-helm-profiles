# usage: make <target>
# example: make install-linkerd

install-linkerd:
	kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
	linkerd check --pre
	linkerd install --crds | kubectl apply -f -
	linkerd install | kubectl apply -f -
	linkerd check
	linkerd viz install | kubectl apply -f - # install the on-cluster metrics stack
	linkerd check

open-linkerd-dashboard:
	linkerd viz dashboard &

uninstall-linkerd:
#	istioctl uninstall -y --purge
#	kubectl delete namespace istio-system
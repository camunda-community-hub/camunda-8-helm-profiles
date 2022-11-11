.PHONY: chaos-mesh
chaos-mesh:
	helm repo add chaos-mesh https://charts.chaos-mesh.org
	-git clone https://github.com/chaos-mesh/chaos-mesh.git
	-cd chaos-mesh && kubectl apply -f manifests/
	helm install chaos-mesh chaos-mesh/chaos-mesh -f chaos-mesh-values.yaml -n default --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock
	kubectl wait --for=condition=Ready pod -n default -l app.kubernetes.io/instance=chaos-mesh --timeout=900s
	kubectl delete validatingWebhookConfigurations.admissionregistration.k8s.io chaos-mesh-validation-auth


.PHONY: clean-chaos-mesh
clean-chaos:
	-rm -rf chaos-mesh
	-helm --namespace default uninstall chaos-mesh
	
	
	
	kubectl apply -f network-chaos.yaml -n default
	-kubectl delete -f network-chaos.yaml -n default
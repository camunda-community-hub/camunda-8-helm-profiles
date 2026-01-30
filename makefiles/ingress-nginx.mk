# Setting up a ingress nginx controller is subtly different for each cloud provider.
# So the ingress-nginx target can now be found in each of the cloud provider specific makefiles.

	--set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
	--set controller.service.annotations."cert-manager.io/cluster-issuer"="letsencrypt" \

.PHONY: ingress-ip-from-service
ingress-ip-from-service:
	$(eval IP := $(shell kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.ip}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1))
	@echo "Ingress controller uses IP address: $(IP)"

.PHONY: ingress-hostname-from-service
ingress-hostname-from-service:
	$(eval IP := $(shell kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.hostname}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1))
	@echo "Ingress controller uses hostname: $(IP)"

.PHONY: clean-ingress
clean-ingress:
	-helm --namespace ingress-nginx uninstall ingress-nginx
	-kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	-kubectl delete namespace ingress-nginx

.PHONY: annotate-ingress-proxy-buffer-size
annotate-ingress-proxy-buffer-size:
	kubectl -n $(CAMUNDA_NAMESPACE) annotate ingress camunda-camunda-platform nginx.ingress.kubernetes.io/proxy-buffer-size=128k

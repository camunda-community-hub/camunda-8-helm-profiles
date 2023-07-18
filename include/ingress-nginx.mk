.PHONY: ingress
ingress: ingress-nginx camunda-values-nginx.yaml

.PHONY: ingress-nginx
ingress-nginx:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait

#	  helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
#	  --set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
#	  --set controller.service.annotations."cert-manager.io/cluster-issuer"="$(clusterIssuer)" \
#	  --set controller.config.error-log-level="debug"; \

.PHONY: ingress-nginx-tls
ingress-nginx-tls:
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update ingress-nginx
	helm search repo ingress-nginx
	helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --wait \
	--set controller.service.annotations."nginx\.ingress.kubernetes.io/ssl-redirect"="true" \
	--set controller.service.annotations."cert-manager.io/cluster-issuer"="letsencrypt" \
	--set controller.service.externalTrafficPolicy=Local

.PHONY: ingress-ip-from-service
ingress-ip-from-service:
	$(eval IP := $(shell kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.ip}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1))
	@echo "Ingress controller uses IP address: $(IP)"

.PHONY: ingress-hostname-from-service
ingress-hostname-from-service:
	$(eval IP := $(shell kubectl get service -w ingress-nginx-controller -o 'go-template={{with .status.loadBalancer.ingress}}{{range .}}{{.hostname}}{{"\n"}}{{end}}{{.err}}{{end}}' -n ingress-nginx 2>/dev/null | head -n1))
	@echo "Ingress controller uses hostname: $(IP)"

# If `baseDomainName` is set to `nip.io`, then find ip address from service to create fully qualified domain name
# Otherwise, just use domain name that was specified in Makefile
.PHONY: fqdn
fqdn: ingress-ip-from-service
	$(eval fqdn ?= $(shell if [ "$(baseDomainName)" == "nip.io" ]; then echo "$(dnsLabel).$(IP).$(baseDomainName)"; else echo "$(dnsLabel).$(baseDomainName)"; fi))
	@echo "Fully qualified domain name is: $(fqdn)"

camunda-values-nginx-all.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/ingress-nginx/camunda-values.yaml > ./camunda-values-nginx-all.yaml; \

.PHONY: clean-ingress
clean-ingress:
	-helm --namespace ingress-nginx uninstall ingress-nginx
	-kubectl delete -n ingress-nginx pvc -l app.kubernetes.io/instance=ingress-nginx
	-kubectl delete namespace ingress-nginx

camunda-values-ingress.yaml: fqdn
	sed "s/localhost/$(fqdn)/g;" $(root)/development/camunda-values-with-ingress.yaml > ./camunda-values-ingress.yaml

.PHONY: external-urls-with-fqdn
external-urls-with-fqdn: fqdn
	@echo To access operate: browse to: http://$(fqdn)/operate
	@echo To access tasklist: browse to: http://$(fqdn)/tasklist
	@echo To access inbound connectors: browse to: http://$(fqdn)/inbound
	@echo To deploy to the cluster: make port-zeebe, then: zbctl status --address localhost:26500 --insecure

.PHONY: external-urls-all
external-urls-all: fqdn
	@echo Keycloak: https://$(fqdn)/auth
	@echo Identity: https://$(fqdn)/identity
	@echo Operate: https://$(fqdn)/operate
	@echo Tasklist: https://$(fqdn)/tasklist
	@echo Optimize: https://$(fqdn)/optimize
	@echo Connectors: https://$(fqdn)/inbound
	@echo Zeebe GRPC: zbctl status --address $(fqdn):443
	@echo Auth URL: https://$(fqdn):443/auth/realms/camunda-platform/protocol/openid-connect/token
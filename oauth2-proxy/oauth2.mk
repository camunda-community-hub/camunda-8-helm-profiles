oauth2-values.yaml:
	if [ -n "$(baseDomainName)" ]; then \
	  sed "s/YOUR_HOSTNAME/$(subDomainName).$(baseDomainName)/g; s/YOUR_CLIENT_SECRET/$(clientSecret)/g" $(root)/oauth2-proxy/oauth2-values.tpl.yaml > ./oauth2-values.yaml; \
	else \
	  sed "s/YOUR_HOSTNAME/$(IP).nip.io/g; s/YOUR_CLIENT_SECRET/$(clientSecret)/g" $(root)/oauth2-proxy/oauth2-values.tpl.yaml > ./oauth2-values.yaml; \
	fi

.PHONY: oauth2-proxy
oauth2-proxy: oauth2-values.yaml
	helm repo add azure-marketplace https://marketplace.azurecr.io/helm/v1/repo
	helm repo update azure-marketplace
	helm install oauth2-proxy azure-marketplace/oauth2-proxy -n ingress-nginx --create-namespace -f oauth2-values.yaml

.PHONY: update-oauth2-proxy
update-oauth2-proxy:
	helm upgrade oauth2-proxy azure-marketplace/oauth2-proxy -n ingress-nginx -f oauth2-values.yaml

.PHONY: oauth2-ingress
oauth2-ingress: ingress-ip-from-service
	if [ -n "$(baseDomainName)" ]; then \
	  cat $(root)/oauth2-proxy/oauth2-ingress.yaml | sed -E "s/YOUR_HOSTNAME/$(subDomainName).$(baseDomainName)/g" | kubectl apply -f - ; \
	else \
	  cat $(root)/oauth2-proxy/oauth2-ingress.yaml | sed -E "s/YOUR_HOSTNAME/$(IP).nip.io/g" | kubectl apply -f - ; \
	fi

.PHONY: zeebe-oauth2-ingress
zeebe-oauth2-ingress: ingress-ip-from-service
	if [ -n "$(baseDomainName)" ]; then \
	  cat $(root)/oauth2-proxy/zeebe-oauth2-ingress.yaml | sed -E "s/YOUR_HOSTNAME/$(subDomainName).$(baseDomainName)/g" | kubectl apply -f - ; \
	else \
	  cat $(root)/oauth2-proxy/zeebe-oauth2-ingress.yaml | sed -E "s/YOUR_HOSTNAME/$(IP).nip.io/g" | kubectl apply -f - ; \
	fi

.PHONY: clean-oauth2-values
clean-oauth2:
	rm -rf oauth2-values.yaml

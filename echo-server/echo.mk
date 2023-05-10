#k -n echo annotate ingress echo-server cert-manager.io/cluster-issuer=letsencrypt

.PHONY: echo
echo: ingress-ip-from-service
	kubectl apply -f $(root)/echo-server/deployment.yaml -n $(namespace)
	if [ -n "$(baseDomainName)" ]; then \
	  cat $(root)/echo-server/ingress.yaml | sed -E "s/YOUR_HOSTNAME/$(subDomainName).$(baseDomainName)/g" | kubectl apply -f - ; \
	else \
	  cat $(root)/echo-server/ingress.yaml | sed -E "s/YOUR_HOSTNAME/$(IP).nip.io/g" | kubectl apply -f - ; \
	fi

.PHONY: clean-echo
clean-echo:
	kubectl delete -f ./echo-server/deployment.yaml -n $(namespace)
	kubectl delete -f ./echo-server/ingress.yaml -n $(namespace)
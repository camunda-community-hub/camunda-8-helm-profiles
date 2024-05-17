.PHONY: create-ca-secret
create-ca-secret:
	-kubectl  -n $(namespace) delete secret "c8sm-custom-ca"
	kubectl -n $(namespace) apply -f $(root)/certs/selfsigned/ca/caSecret.yaml

.PHONY: c8sm-issuer
c8sm-issuer:
	-kubectl -n $(namespace) delete issuer "c8sm-issuer"
	kubectl -n $(namespace) apply -f $(root)/certs/selfsigned/ca/caIssuer.yaml

.PHONY: k8s-cert
k8s-cert:
	-kubectl -n $(namespace) delete certificate "k8s-cert"
	kubectl -n $(namespace) apply -f $(root)/certs/selfsigned/k8sCert.yaml

.PHONY: netshoot
netshoot:
	kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -n $(namespace)

camunda-values-tls-enabled.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;s/YOUR_EMAIL/$(camundaDockerRegistryEmail)/g;" $(root)/certs/selfsigned/camunda-values-tls-enabled.yaml > $(chartValues);



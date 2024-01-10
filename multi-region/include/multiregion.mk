camunda-values-multiregion.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g; s/YOUR_EMAIL/$(camundaDockerRegistryEmail)/g; s/REGIONS/$(regions)/g; s/REGION_ID/$(regionId)/g; s/NAMESPACE1/$(namespace)/g; s/NAMESPACE2/$(namespace2)/g;" $(root)/multi-region/include/camunda-values-multiregion.tpl.yaml > $(chartValues);

.PHONY: restart-dns
restart-dns:
	kubectl -n kube-system rollout restart deployment coredns

corednsms.yaml:
	sed "s/NAMESPACE2/$(namespace2)/g; s/DNS_IP_ADDRESS/$(dnsLBIp)/g; " $(root)/multi-region/include/corednsms.tpl.yaml > corednsms.yaml;

.PHONY: remove-corednsms
remove-corednsms:
	-rm -rf corednsms.yaml

.PHONY: apply-corednsms
apply-corednsms:
	kubectl apply -f corednsms.yaml

.PHONY: create-custom-dns
create-custom-dns: remove-corednsms corednsms.yaml apply-corednsms remove-corednsms restart-dns

.PHONY: netshoot
netshoot:
	kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -n $(namespace)

.PHONY: create-dns-lb
create-dns-lb:
	kubectl apply -f $(root)/multi-region/include/dns-lb.yaml

.PHONY: dns-ip
dns-ip:
	$(eval dnsip ?= $(shell kubectl get services kube-dns-lb -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'))
	@echo "DNS IP Address: $(dnsip)"


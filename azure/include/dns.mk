# https://learn.microsoft.com/en-us/azure/dns/dns-getstarted-cli
.PHONY: dns-zone
dns-zone:
	az group create --name dns-rg --location $(region)
	az network dns zone create -g dns-rg -n $(domain)
	az network dns record-set a add-record -g dns-rg -z $(domain) -n zeebe -a $(IP)
	az network dns record-set list -g dns-rg -z $(domain)

.PHONY: dns-test
dns-test:
	az network dns record-set ns show --resource-group dns-rg --zone-name $(fqdn) --name @
#	nslookup zeebe.$(fqdn) <name server name>
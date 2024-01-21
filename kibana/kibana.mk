.PHONY: install-kibana
install-kibana:
	helm repo add elastic https://helm.elastic.co
	helm repo add stable https://charts.helm.sh/stable
	helm repo update elastic stable
	helm upgrade kibana elastic/kibana --version 7.17.3 --atomic --install --namespace $(namespace) --set elasticsearchHosts=http://camunda-elasticsearch:9200

.PHONY: clean-kibana
clean-kibana:
	-helm uninstall kibana --namespace $(namespace)

.PHONY: port-kibana
port-kibana:
	kubectl port-forward svc/kibana-kibana 5601:5601 -n $(namespace)

.PHONY: template-kibana
template-kibana:
	helm template kibana elastic/kibana --version $(kibanaVersion) --skip-crds --output-dir .
	@echo "To apply the templates use: kubectl apply -f kibana/templates/ -n $(namespace)"
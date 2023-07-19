tasklist-configmap-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/tasklist/include/configmap-importer-archiver.tpl.yaml > ./tasklist-configmap-importer-archiver.yaml;

tasklist-configmap-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/tasklist/include/configmap-webapp.tpl.yaml > ./tasklist-configmap-webapp.yaml;

tasklist-deployment-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/tasklist/include/deployment-importer-archiver.tpl.yaml > ./tasklist-deployment-importer-archiver.yaml;

tasklist-deployment-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/tasklist/include/deployment-webapp.tpl.yaml > ./tasklist-deployment-webapp.yaml;

#tasklist-service-importer-archiver.yaml:
#	cp $(root)/tasklist/include/service-importer-archiver.tpl.yaml ./tasklist-service-importer-archiver.yaml;

tasklist-service-webapp.yaml:
	cp $(root)/tasklist/include/service-webapp.tpl.yaml ./tasklist-service-webapp.yaml;

tasklist-camunda-ingress.yaml:
	cp $(root)/tasklist/include/camunda-ingress.tpl.yaml ./tasklist-camunda-ingress.yaml;

tasklist-tasklist-ingress.yaml:
	cp $(root)/tasklist/include/tasklist-ingress.tpl.yaml ./tasklist-tasklist-ingress.yaml;

.PHONY: tasklist-yaml-files
tasklist-yaml-files: tasklist-configmap-importer-archiver.yaml tasklist-configmap-webapp.yaml tasklist-deployment-importer-archiver.yaml tasklist-deployment-webapp.yaml tasklist-camunda-ingress.yaml tasklist-tasklist-ingress.yaml tasklist-service-webapp.yaml #tasklist-service-importer-archiver.yaml

.PHONY: clean-tasklist-yaml-files
tasklist-clean-yaml-files:
	rm ./tasklist-configmap-importer-archiver.yaml;
	rm ./tasklist-configmap-webapp.yaml;
	rm ./tasklist-deployment-importer-archiver.yaml;
	rm ./tasklist-deployment-webapp.yaml;
#	rm ./tasklist-service-importer-archiver.yaml;
	rm ./tasklist-service-webapp.yaml;
	rm ./tasklist-camunda-ingress.yaml;
	rm ./tasklist-tasklist-ingress.yaml;

.PHONY: tasklist-delete
tasklist-delete:
	kubectl get deployments -l app.kubernetes.io/component=tasklist -o name | xargs kubectl delete
	kubectl get service -l app.kubernetes.io/component=tasklist -o name | xargs kubectl delete

.PHONY: tasklist-install
tasklist-install: tasklist-yaml-files
	kubectl apply -f ./tasklist-configmap-importer-archiver.yaml
	kubectl apply -f ./tasklist-configmap-webapp.yaml
	kubectl apply -f ./tasklist-deployment-importer-archiver.yaml
	kubectl apply -f ./tasklist-deployment-webapp.yaml
#	kubectl apply -f ./tasklist-service-importer-archiver.yaml
	kubectl apply -f ./tasklist-service-webapp.yaml
	kubectl apply -f ./tasklist-camunda-ingress.yaml
	kubectl apply -f ./tasklist-tasklist-ingress.yaml

.PHONY: tasklist-clean
tasklist-clean: tasklist-clean-yaml-files
	kubectl delete -f ./tasklist-deployment-importer-archiver.yaml
	kubectl delete -f ./tasklist-deployment-webapp.yaml
	kubectl delete -f ./tasklist-configmap-importer-archiver.yaml
	kubectl delete -f ./tasklist-configmap-webapp.yaml
#	kubectl delete -f ./tasklist-service-importer-archiver.yaml
	kubectl delete -f ./tasklist-service-webapp.yaml


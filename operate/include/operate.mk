operate-configmap-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/configmap-importer-archiver.tpl.yaml > ./operate-configmap-importer-archiver.yaml;

operate-configmap-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/configmap-webapp.tpl.yaml > ./operate-configmap-webapp.yaml;

operate-deployment-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/deployment-importer-archiver.tpl.yaml > ./operate-deployment-importer-archiver.yaml;

operate-deployment-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/deployment-webapp.tpl.yaml > ./operate-deployment-webapp.yaml;

.PHONY: operate-yaml-files
operate-yaml-files: operate-configmap-importer-archiver.yaml operate-configmap-webapp.yaml operate-deployment-importer-archiver.yaml operate-deployment-webapp.yaml

.PHONY: clean-operate-yaml-files
operate-clean-yaml-files:
	rm ./operate-configmap-importer-archiver.yaml;
	rm ./operate-configmap-webapp.yaml;
	rm ./operate-deployment-importer-archiver.yaml;
	rm ./operate-deployment-webapp.yaml;

.PHONY: operate-delete
operate-delete:
	kubectl get deployments -l app.kubernetes.io/component=operate -o name | xargs kubectl delete

.PHONY: operate-install
operate-install: operate-yaml-files
	kubectl apply -f ./configmap-importer-archiver.yaml
	kubectl apply -f ./configmap-webapp-archiver.yaml
	kubectl apply -f ./deployment-importer-archiver.yaml
	kubectl apply -f ./deployment-webapp.yaml

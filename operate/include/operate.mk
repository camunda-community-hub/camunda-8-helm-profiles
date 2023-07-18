operate-configmap-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/configmap-importer-archiver.tpl.yaml > ./operate-configmap-importer-archiver.yaml;

operate-configmap-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/configmap-webapp.tpl.yaml > ./operate-configmap-webapp.yaml;

operate-deployment-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/deployment-importer-archiver.tpl.yaml > ./operate-deployment-importer-archiver.yaml;

operate-deployment-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/deployment-webapp.tpl.yaml > ./operate-deployment-webapp.yaml;

#operate-service-importer-archiver.yaml:
#	cp $(root)/operate/include/service-importer-archiver.tpl.yaml ./operate-service-importer-archiver.yaml;

operate-service-webapp.yaml:
	cp $(root)/operate/include/service-webapp.tpl.yaml ./operate-service-webapp.yaml;

operate-camunda-ingress.yaml:
	cp $(root)/operate/include/camunda-ingress.tpl.yaml ./operate-camunda-ingress.yaml;

operate-operate-ingress.yaml:
	cp $(root)/operate/include/operate-ingress.tpl.yaml ./operate-operate-ingress.yaml;

.PHONY: operate-yaml-files
operate-yaml-files: operate-configmap-importer-archiver.yaml operate-configmap-webapp.yaml operate-deployment-importer-archiver.yaml operate-deployment-webapp.yaml operate-camunda-ingress.yaml operate-operate-ingress.yaml operate-service-webapp.yaml #operate-service-importer-archiver.yaml

.PHONY: clean-operate-yaml-files
operate-clean-yaml-files:
	rm ./operate-configmap-importer-archiver.yaml;
	rm ./operate-configmap-webapp.yaml;
	rm ./operate-deployment-importer-archiver.yaml;
	rm ./operate-deployment-webapp.yaml;
#	rm ./operate-service-importer-archiver.yaml;
	rm ./operate-service-webapp.yaml;
	rm ./operate-camunda-ingress.yaml;
	rm ./operate-operate-ingress.yaml;

.PHONY: operate-delete
operate-delete:
	kubectl get deployments -l app.kubernetes.io/component=operate -o name | xargs kubectl delete
	kubectl get service -l app.kubernetes.io/component=operate -o name | xargs kubectl delete

.PHONY: operate-install
operate-install: operate-yaml-files
	kubectl apply -f ./operate-configmap-importer-archiver.yaml
	kubectl apply -f ./operate-configmap-webapp.yaml
	kubectl apply -f ./operate-deployment-importer-archiver.yaml
	kubectl apply -f ./operate-deployment-webapp.yaml
#	kubectl apply -f ./operate-service-importer-archiver.yaml
	kubectl apply -f ./operate-service-webapp.yaml
	kubectl apply -f ./operate-camunda-ingress.yaml
	kubectl apply -f ./operate-operate-ingress.yaml

.PHONY: operate-clean
operate-clean: operate-clean-yaml-files
	kubectl delete -f ./operate-deployment-importer-archiver.yaml
	kubectl delete -f ./operate-deployment-webapp.yaml
	kubectl delete -f ./operate-configmap-importer-archiver.yaml
	kubectl delete -f ./operate-configmap-webapp.yaml
#	kubectl delete -f ./operate-service-importer-archiver.yaml
	kubectl delete -f ./operate-service-webapp.yaml


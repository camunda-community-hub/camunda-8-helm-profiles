configmap-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/configmap-importer-archiver.tpl.yaml > ./configmap-importer-archiver.yaml;

configmap-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/configmap-webapp.tpl.yaml > ./configmap-webapp.yaml;

deployment-importer-archiver.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/deployment-importer-archiver.tpl.yaml > ./deployment-importer-archiver.yaml;

deployment-webapp.yaml: fqdn
	sed "s/YOUR_HOSTNAME/$(fqdn)/g;" $(root)/operate/include/deployment-webapp.tpl.yaml > ./deployment-webapp.yaml;


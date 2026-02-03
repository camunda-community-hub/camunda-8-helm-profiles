# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= myMinimalC8

# Camunda installation
CAMUNDA_NAMESPACE ?= camunda
CAMUNDA_RELEASE_NAME ?= camunda
CAMUNDA_CHART ?= camunda/camunda-platform

CAMUNDA_HELM_CHART_VERSION ?= 12.4.0
CAMUNDA_VERSION ?= 8.7.10

HOST_NAME ?= camunda.my-domain.com

CAMUNDA_HELM_VALUES ?= \
	$(root)/camunda-values.yaml.d/8.7/ingress-nginx-tls.yaml \
	my-camunda-values.yaml

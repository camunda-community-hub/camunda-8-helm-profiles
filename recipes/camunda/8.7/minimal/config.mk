# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= myMinimalC8

# Camunda installation
CAMUNDA_NAMESPACE ?= camunda
CAMUNDA_RELEASE_NAME ?= camunda
CAMUNDA_CHART ?= camunda/camunda-platform

CAMUNDA_HELM_CHART_VERSION ?= 12.4.0
CAMUNDA_VERSION ?= 8.7.10

CAMUNDA_HELM_VALUES ?= \
	$(root)/camunda-values.yaml.d/8.7/cluster-size-mini.yaml \
	$(root)/camunda-values.yaml.d/8.7/persistence-in-memory.yaml \
	$(root)/camunda-values.yaml.d/8.7/elasticsearch-disabled.yaml \
	$(root)/camunda-values.yaml.d/8.7/identity-disabled.yaml \
	$(root)/camunda-values.yaml.d/8.7/connectors-disabled.yaml \
	$(root)/camunda-values.yaml.d/8.7/pod-anti-affinity-disabled.yaml \
	$(root)/camunda-values.yaml.d/8.7/prometheus-service-monitor.yaml \
	my-camunda-values.yaml

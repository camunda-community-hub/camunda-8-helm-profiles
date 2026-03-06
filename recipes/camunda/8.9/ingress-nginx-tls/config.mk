# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= mydeployment

# Camunda installation
CAMUNDA_NAMESPACE ?= camunda
CAMUNDA_RELEASE_NAME ?= camunda

CAMUNDA_CHART ?= camunda/camunda-platform
CAMUNDA_HELM_CHART_VERSION ?= 14.0.0-alpha4
CAMUNDA_VERSION ?= 8.9.0-alpha4

CAMUNDA_HELM_VALUES ?= \
  $(root)/camunda-values.yaml.d/8.9/disable-all.yaml \
  $(root)/camunda-values.yaml.d/8.9/enable-elasticsearch.yaml \
  $(root)/camunda-values.yaml.d/8.9/enable-ingress-nginx.yaml \
  $(root)/camunda-values.yaml.d/8.9/orchestration-elasticsearch.yaml \
  ./my-camunda-values.yaml

DEFAULT_PASSWORD ?= demo

CAMUNDA_CLUSTER_SIZE ?= 1
CAMUNDA_REPLICATION_FACTOR ?= 1
CAMUNDA_PARTITION_COUNT ?= 1

# Networking
CAMUNDA_INGRESS_NAME ?= camunda-camunda-platform-http
CAMUNDA_INGRESS_GRPC_NAME ?= camunda-camunda-platform-grpc
ORCHESTRATION_EXT_URL ?= http://localhost:8080
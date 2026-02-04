# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= mydeployment

# Postgresql
# If you are using the aurora postgres recipe this will be dynamically discovered
POSTGRES_HOST ?= camunda-identity-postgresql
POSTGRES_CAMUNDA_DB ?= camunda
POSTGRES_CAMUNDA_USERNAME ?= camunda

# Camunda installation
CAMUNDA_NAMESPACE ?= camunda
CAMUNDA_RELEASE_NAME ?= camunda
#CAMUNDA_CHART ?= camunda/camunda-platfor
CAMUNDA_CHART ?= /Users/dave/code/camunda-platform-helm/charts/camunda-platform-8.9

CAMUNDA_HELM_CHART_VERSION ?= 14.0.0-alpha3
CAMUNDA_VERSION ?= 8.9.0-alpha3

CAMUNDA_HELM_VALUES ?= \
  $(root)/camunda-values.yaml.d/8.9/disable-all.yaml \
  $(root)/camunda-values.yaml.d/8.9/enable-identity-postgres.yaml \
  $(root)/camunda-values.yaml.d/8.9/orchestration-rdbms-postgres.yaml \
  ./my-camunda-values.yaml

DEFAULT_PASSWORD ?= demo

CAMUNDA_CLUSTER_SIZE ?= 1
CAMUNDA_REPLICATION_FACTOR ?= 1
CAMUNDA_PARTITION_COUNT ?= 1

# Networking
ORCHESTRATION_EXT_URL ?= http://localhost:8080
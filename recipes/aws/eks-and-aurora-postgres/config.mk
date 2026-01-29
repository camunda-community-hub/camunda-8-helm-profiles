# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= mydeployment

# Cloud environment and K8s cluster
REGION ?= ca-central-1
ZONES ?= ['ca-central-1a', 'ca-central-1b']

MACHINE_TYPE ?= c6i.4xlarge
CLUSTER_VERSION ?= 1.34
VOLUME_SIZE ?= 100

DESIRED_SIZE ?= 3
MIN_SIZE ?= 1
MAX_SIZE ?= 6

# Aurora Postgresql
POSTGRES_MASTER_USERNAME ?= postgres
POSTGRES_MASTER_PASSWORD ?= CHANGEME

POSTGRES_KEYCLOAK_DB ?= bitnami_keycloak
POSTGRES_KEYCLOAK_USERNAME ?= bn_keycloak

POSTGRES_IDENTITY_DB ?= identity
POSTGRES_IDENTITY_USERNAME ?= identity

POSTGRES_MODELER_DB ?= modeler
POSTGRES_MODELER_USERNAME ?= modeler

POSTGRES_CAMUNDA_DB ?= camunda
POSTGRES_CAMUNDA_USERNAME ?= camunda

DEFAULT_PASSWORD ?= demo

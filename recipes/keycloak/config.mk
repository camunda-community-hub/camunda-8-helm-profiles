# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

CAMUNDA_NAMESPACE ?= camunda

KEYCLOAK_TEMP_ADMIN_USERNAME ?= camunda_admin
KEYCLOAK_TEMP_ADMIN_PASSWORD ?= CHANGEME

POSTGRES_HOST ?= xxx-cluster.cluster-xxx.ca-central-1.rds.amazonaws.com
POSTGRES_KEYCLOAK_DB ?= bitnami_keycloak
POSTGRES_KEYCLOAK_USERNAME ?= bn_keycloak
POSTGRES_KEYCLOAK_PASSWORD ?= demo
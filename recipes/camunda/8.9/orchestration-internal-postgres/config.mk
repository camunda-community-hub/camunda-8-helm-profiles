# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= paul

# Postgresql
# If you are using the aurora postgres recipe this will be dynamically discovered
POSTGRES_HOST ?= camunda-identity-postgresql
POSTGRES_CAMUNDA_DB ?= camunda
POSTGRES_CAMUNDA_USERNAME ?= camunda

# Camunda installation
CAMUNDA_NAMESPACE ?= camunda
CAMUNDA_RELEASE_NAME ?= camunda
CAMUNDA_CHART ?= camunda/camunda-platform

CAMUNDA_HELM_CHART_VERSION ?= 14.0.0-alpha4
CAMUNDA_VERSION ?= 8.9.0-alpha4

DEFAULT_PASSWORD ?= demo

CAMUNDA_CLUSTER_SIZE ?= 1
CAMUNDA_REPLICATION_FACTOR ?= 1
CAMUNDA_PARTITION_COUNT ?= 1

# Networking
ORCHESTRATION_EXT_URL ?= http://localhost:8080

# ── Single-Region Values (default) ─────────────────────────────────────────
CAMUNDA_HELM_VALUES ?= \
  $(root)/camunda-values.yaml.d/8.9/disable-all.yaml \
  $(root)/camunda-values.yaml.d/8.9/enable-identity-postgres.yaml \
  $(root)/camunda-values.yaml.d/8.9/orchestration-rdbms-postgres.yaml \
  ./my-camunda-values.yaml

# ── Dual-Region Settings ───────────────────────────────────────────────────
# Override the variables below in your root config.mk or pass them on the command line.
#
# To deploy dual-region:
#   make deploy-region0 CLUSTER_0=paul-region0 CLUSTER_1=paul-region1
#
# Or set these here / in root config.mk:

# ── AWS Regions and Clusters ────────────────────────────────────────────────
# Region 0 (primary)
AWS_REGION_0 ?= us-west-1
AWS_ZONES_0 ?= ['us-west-1a', 'us-west-1b']
CLUSTER_0 ?= $(DEPLOYMENT_NAME)-region0
CAMUNDA_NAMESPACE_0 ?= camunda-region0

# Region 1 (secondary)
AWS_REGION_1 ?= ca-central-1
AWS_ZONES_1 ?= ['ca-central-1a', 'ca-central-1b']
CLUSTER_1 ?= $(DEPLOYMENT_NAME)-region1
CAMUNDA_NAMESPACE_1 ?= camunda-region1


# Dual-region helm values composition (includes dual-region.yaml overlay)
# Used by: make deploy-region0, make deploy-region1
CAMUNDA_HELM_VALUES_DR ?= \
  $(root)/camunda-values.yaml.d/8.9/disable-all.yaml \
  $(root)/camunda-values.yaml.d/8.9/enable-identity-postgres.yaml \
  $(root)/camunda-values.yaml.d/8.9/orchestration-rdbms-postgres.yaml \
  $(root)/camunda-values.yaml.d/8.9/dual-region.yaml \
  ./my-camunda-values.yaml
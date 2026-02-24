# Camunda 8.9 Dual-Region EKS Recipe - Default Configuration
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= paul

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

# EKS cluster settings (shared)
AWS_MACHINE_TYPE ?= c6i.4xlarge
CLUSTER_VERSION ?= 1.34
VOLUME_SIZE ?= 100
DESIRED_SIZE ?= 4
MIN_SIZE ?= 1
MAX_SIZE ?= 6

# VPC CIDRs — MUST be non-overlapping for VPC peering
VPC_CIDR_0 ?= 10.192.0.0/16
VPC_CIDR_1 ?= 10.202.0.0/16

# ── Camunda installation ────────────────────────────────────────────────────
CAMUNDA_RELEASE_NAME ?= camunda
CAMUNDA_CHART ?= camunda/camunda-platform

CAMUNDA_HELM_CHART_VERSION ?= 14.0.0-alpha4
CAMUNDA_VERSION ?= 8.9.0-alpha4

# Zeebe cluster sizing (total across BOTH regions)
CAMUNDA_CLUSTER_SIZE ?= 4
CAMUNDA_REPLICATION_FACTOR ?= 4
CAMUNDA_PARTITION_COUNT ?= 4

# Brokers per region = CAMUNDA_CLUSTER_SIZE / 2
BROKERS_PER_REGION ?= $(shell echo $$(( $(CAMUNDA_CLUSTER_SIZE) / 2 )))

# ── PostgreSQL ──────────────────────────────────────────────────────────────
POSTGRES_HOST ?= $(CAMUNDA_RELEASE_NAME)-identity-postgresql
POSTGRES_CAMUNDA_DB ?= camunda
POSTGRES_CAMUNDA_USERNAME ?= camunda
DEFAULT_PASSWORD ?= demo

# ── Helm values composition ────────────────────────────────────────────────
# The multi-region values file includes disable-all implicitly via its own settings
CAMUNDA_HELM_VALUES ?= \
  $(root)/camunda-values.yaml.d/8.9/multi-region-internal-postgres.yaml \
  ./my-camunda-values.yaml
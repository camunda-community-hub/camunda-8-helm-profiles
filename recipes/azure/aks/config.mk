# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= mydeployment

# Cloud environment and K8s cluster
REGION ?= eastus

MACHINE_TYPE ?= Standard_A8_v2
CLUSTER_VERSION ?= 1.34

MIN_SIZE ?= 1
MAX_SIZE ?= 6

# Optional, for cert manager
CERT_MANAGER_EMAIL ?= someone@somewhere.com


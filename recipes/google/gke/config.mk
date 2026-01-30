# Theses are the default values used by this recipe
# Create a config.mk file in the root directory of this project to override variables for your specific environment

DEPLOYMENT_NAME ?= mydeployment

# Cloud environment and K8s cluster
GCP_PROJECT ?= xyz
REGION ?= us-east4-a

MACHINE_TYPE ?= n1-standard-16
CLUSTER_VERSION ?= 1.34

MIN_SIZE ?= 1
MAX_SIZE ?= 10


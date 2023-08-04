# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster


# Set which AWS region to use
# see: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
# Sample value:
region ?= us-east-1

ifndef region
$(error 'region' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set AWS zones
# see: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
# Sample value:
zones ?= ['us-east-1a', 'us-east-1b']

ifndef zones
$(error 'zones' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'clusterName'
# This controls the name of the GKE cluster in use.
# If you already have a GKE cluster that you want to use, set the name of the existing GKE cluster here.
# If you do not yet have a GKE cluster, then running `make kube` will create a new GKE cluster with the name set here
# Sample value:
#clusterName ?= camunda-01

ifndef clusterName
$(error 'clusterName' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'clusterVersion'
# This controls the name of the Kubernetes cluster in use.
# If you already have a cluster that you want to use, set the name of the existing cluster here.
# If you do not yet have a cluster, then running `make kube` will create a new cluster with the name set here
# Sample value:
clusterVersion ?= 1.25

ifndef clusterVersion
$(error 'clusterVersion' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'machineType'
# This controls the machine types of nodes in the cluster. It will only be used when creating a new cluster
machineType ?= c6i.4xlarge

ifndef machineType
$(error 'machineType' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Note: Currently, auto scaling configuration using these scripts for AWS doesn't seem to be reliable

# Set 'desiredSize'
# Desired number of nodes in the cluster in the context of autoscaling
desiredSize ?= 3

ifndef desiredSize
$(error 'desiredSize' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'minSize'
# Minimum number of nodes in the cluster in the context of autoscaling
minSize ?= 1

ifndef minSize
$(error 'minSize' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'maxSize'
# Max number of nodes in the cluster in the context of autoscaling
maxSize ?= 3

ifndef maxSize
$(error 'maxSize' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'namespace'
# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda

ifndef namespace
$(error 'namespace' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'camundaDockerRegistryUrl'
# Note: this is not used unless you're using a profile that installs Web Modeler
# This controls the url to the camunda registry.
# Camunda Enterprise customers need access to this registry in order to install Web Modeler
# https://github.com/camunda/camunda-platform-helm/tree/main/charts/camunda-platform#web-modeler
camundaDockerRegistryUrl ?= https://registry.camunda.cloud/

ifndef camundaDockerRegistryUrl
$(error 'camundaDockerRegistryUrl' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'camundaDockerRegistryUsername'
# Note: this is not used unless you're using a profile that installs Web Modeler
# This controls the username used to connect to the camunda registry.
# Camunda Enterprise customers need access to this registry in order to install Web Modeler
# https://github.com/camunda/camunda-platform-helm/tree/main/charts/camunda-platform#web-modeler
camundaDockerRegistryUsername ?= YOUR_USERNAME

ifndef camundaDockerRegistryUsername
$(error 'camundaDockerRegistryUsername' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'camundaDockerRegistryPassword'
# Note: this is not used unless you're using a profile that installs Web Modeler
# This controls the password used to connect to the camunda registry.
# Camunda Enterprise customers need access to this registry in order to install Web Modeler
# https://github.com/camunda/camunda-platform-helm/tree/main/charts/camunda-platform#web-modeler
camundaDockerRegistryPassword ?= YOUR_PASSWORD

ifndef camundaDockerRegistryPassword
$(error 'camundaDockerRegistryPassword' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

# Set 'camundaDockerRegistryEmail'
# Note: this is not used unless you're using a profile that installs Web Modeler
# This controls the email used to connect to the camunda registry.
# Camunda Enterprise customers need access to this registry in order to install Web Modeler
# https://github.com/camunda/camunda-platform-helm/tree/main/charts/camunda-platform#web-modeler
camundaDockerRegistryEmail ?= YOUR_EMAIL

ifndef camundaDockerRegistryEmail
$(error 'camundaDockerRegistryEmail' is mandatory. To fix, edit file: $(root)/aws/config/properties.mk )
endif

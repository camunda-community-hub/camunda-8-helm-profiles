# filename:		properties-local.mk
# purpose:		Provide local settings for how to run kubernetes at Google
#
# Set the following for your specific environment
# Already have a Cluster? Set these values to point to your existing environment
# Otherwise, these values will be used to create a new Cluster

# ----------------------------------------------------------------------------
# Assign 'project' as your own Google Project
# Howto decide value:
#		1)	Login to your google cloud and establish this project
#		2)  Enable kubernetes for the project in
#
# Sample values:
# project ?= camunda-researchanddevelopment

ifndef project
$(error 'project' is mandatory. Update file 'properties-local.mk' )
endif

# ----------------------------------------------------------------------------
# Assign 'region'
# see: https://cloud.withgoogle.com/region-picker/
# purpose:	This make script uses region to create project at Google
#
#region ?= us-central1-a

ifndef region
$(error 'region' is mandatory. Update file 'properties-local.mk' )
endif


clusterName ?= camunda

machineType ?= n1-standard-16
minSize ?= 1
maxSize ?= 6
#
# Camunda components will be installed into the following Kubernetes namespace
namespace ?= camunda

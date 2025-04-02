#!/bin/bash

###############################################################################
# Important: Adjust the following environment variables to your setup         #
###############################################################################

# The script must be executed with
# . ./export_environment_prerequisites.sh
# to export the environment variables to the current shell

# The Kubernetes namespaces for each region where Camunda 8 should be running
# Namespace names must be unique to route the traffic
export CAMUNDA_NAMESPACE_0=camunda-r0
export CAMUNDA_NAMESPACE_1=camunda-r1

# The Helm release name used for installing Camunda 8 in both Kubernetes clusters
export HELM_RELEASE_NAME=camunda
# renovate: datasource=helm depName=camunda-platform registryUrl=https://helm.camunda.io versioning=regex:^11(\.(?<minor>\d+))?(\.(?<patch>\d+))?$
export HELM_CHART_VERSION=11.3.0

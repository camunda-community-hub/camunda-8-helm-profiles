# Kubernetes namespace
namespace ?= camunda-r1
# Helm release name
release ?= camunda
# Helm chart version for Camunda
# renovate: datasource=helm depName=camunda-platform registryUrl=https://helm.camunda.io versioning=regex:^11(\.(?<minor>\d+))?(\.(?<patch>\d+))?$
chartVersion ?= 11.3.0
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform --version $(chartVersion)
# Helm chart values
chartValues ?= ../camunda-values.d/cluster-size.yaml \
	-f ../camunda-values.d/dual-region.yaml \
	-f ../camunda-values.d/dual-region-disable-unsupported-components.yaml \
	-f ../camunda-values.d/env.yaml \
	-f ../camunda-values.d/elasticsearch-disabled.yaml \
	-f region1.yaml

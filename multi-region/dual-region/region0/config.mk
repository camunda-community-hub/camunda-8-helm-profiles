# Kubernetes namespace
namespace ?= camunda-r0
# Helm release name
release ?= camunda
# Helm chart version for Camunda
# renovate: datasource=helm depName=camunda-platform registryUrl=https://helm.camunda.io versioning=regex:^11(\.(?<minor>\d+))?(\.(?<patch>\d+))?$
chartVersion ?= 11.3.0
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform --version $(chartVersion)
# Helm chart values

chartValues ?= \
	   "../../../camunda-values.d/cluster-size-mini-dual-region.yaml" \
	-f "../../../camunda-values.d/dual-region.yaml" \
	-f "../../../camunda-values.d/elasticsearch-2.5-region-stretch-cluster.yaml" \
	-f "region0.yaml"

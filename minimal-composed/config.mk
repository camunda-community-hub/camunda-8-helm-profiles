# Kubernetes namespace
namespace ?= camunda
# Helm release name
release ?= camunda
# Helm chart version for Camunda
# renovate: datasource=helm depName=camunda-platform registryUrl=https://helm.camunda.io versioning=regex:^11(\.(?<minor>\d+))?(\.(?<patch>\d+))?$
chartVersion ?= 12.4.0
# Helm chart coordinates for Camunda
chart ?= camunda/camunda-platform --version $(chartVersion)
# Helm chart values

chartValues ?= \
	   "../camunda-values.d/cluster-size-mini.yaml" \
	-f "../camunda-values.d/persistence-in-memory.yaml" \
	-f "../camunda-values.d/elasticsearch-disabled.yaml" \
	-f "../camunda-values.d/identity-disabled.yaml" \
	-f "../camunda-values.d/connectors-disabled.yaml" \
	-f "../camunda-values.d/pod-anti-affinity-disabled.yaml" \
	-f "../camunda-values.d/prometheus-service-monitor.yaml" \
	-f "camunda-values.yaml"

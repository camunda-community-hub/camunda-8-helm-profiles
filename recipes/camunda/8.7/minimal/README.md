# Minimal In-Memory Helm Profile for Camunda 8

The minimal possible configuration for Camunda Platform 8 that runs entirely in memory without any persistent storage or external dependencies. This profile is ideal for development, testing, or demo environments where you need a lightweight Camunda setup that can start quickly and doesn't require data persistence.

This folder contains [Helm](https://helm.sh/) chart value configuration for installing the [Camunda Platform Helm Chart](https://helm.camunda.io/) on an existing Kubernetes cluster. A [Makefile](Makefile) is provided to automate the installation process.

## Features

This profile provides:
- **Mini cluster size**: Minimal resource allocation for all components
- **In-memory persistence**: No persistent volumes or storage requirements
- **Disabled components**: Elasticsearch, Identity, and Connectors are turned off
- **No anti-affinity**: Pods can be scheduled on the same nodes
- **Prometheus monitoring**: Service monitor enabled for metrics collection

## Prerequisites

- An existing Kubernetes cluster using Kind, Google, AWS or Azure, etc
- A Prometheus instance configured to scrape ServiceMonitors (see the `metrics` recipe) 
- `kubectl` configured to connect to your cluster
- `helm` version 3.7.0 or later
- GNU `make`
- The Camunda Platform Helm Chart (can be downloaded by running `make chart`)
- The Kubernetes namespace `camunda` (configured in [`config.mk`](config.mk) and created by running `make namespace`)

## Configuration

The profile uses the following configuration files:

- [`config.mk`](config.mk): Defines chart version, namespace, and values files to include
- [`camunda-values.yaml`](camunda-values.yaml): Additional custom overrides (minimal by design)
- Shared values from `../camunda-values.yaml.d/`:
  - `cluster-size-mini.yaml`: Minimal resource allocation
  - `persistence-in-memory.yaml`: In-memory storage configuration
  - `elasticsearch-disabled.yaml`: Disables Elasticsearch dependency
  - `identity-disabled.yaml`: Disables Identity service
  - `connectors-disabled.yaml`: Disables Connectors
  - `pod-anti-affinity-disabled.yaml`: Allows pods on same nodes
  - `prometheus-service-monitor.yaml`: Enables Prometheus monitoring

## Install

```bash
make
```

This will install Camunda Platform with the minimal in-memory configuration into the `camunda` namespace using the following command:

```sh
helm upgrade --install --namespace camunda camunda camunda/camunda-platform --version 12.4.0 \
  -f "../camunda-values.d/cluster-size-mini.yaml" \
  -f "../camunda-values.d/persistence-in-memory.yaml" \
  -f "../camunda-values.d/elasticsearch-disabled.yaml" \
  -f "../camunda-values.d/identity-disabled.yaml" \
  -f "../camunda-values.d/connectors-disabled.yaml" \
  -f "../camunda-values.d/pod-anti-affinity-disabled.yaml" \
  -f "../camunda-values.d/prometheus-service-monitor.yaml" \
  -f "camunda-values.yaml" \
  --skip-crds
```

## Verify Installation

Check that all pods are running:

```bash
make pods
```

Access the services:

```bash
# Port forward to access Zeebe Gateway
make port-zeebe
```

Then access:
- Zeebe Gateway: localhost:26500

## Uninstall

```bash
make clean
```

This will remove the Camunda installation and clean up all resources.

## Use Cases

This profile is perfect for:

- **Development environments**: Quick setup for local development
- **CI/CD testing**: Fast startup for automated tests
- **Demos and workshops**: Lightweight setup for presentations
- **Learning**: Simple environment to explore Camunda features
- **Resource-constrained environments**: Minimal resource requirements

## Limitations

⚠️ **Important**: This configuration is **not suitable for production** use because:

- **No data persistence**: All data is lost when pods restart
- **No high availability**: Single instances of all components
- **Limited functionality**: Elasticsearch-dependent features unavailable
- **No authentication**: Identity service is disabled
- **No connectors**: External system integrations unavailable

## Resource Requirements

This minimal configuration has very low resource requirements:
- **Memory**: ~2-4 GB total
- **CPU**: ~1-2 cores total
- **Storage**: No persistent storage needed

## Customization

To customize this profile:

1. Edit [`camunda-values.yaml`](camunda-values.yaml) for additional overrides
2. Modify [`config.mk`](config.mk) to change chart version or add/remove value files
3. Create additional value files in `../camunda-values.yaml.d/` for reusable configurations

## Troubleshooting

### Pods not starting
- Check resource availability: `kubectl describe nodes`
- Check pod events: `kubectl describe pod <pod-name> -n camunda`

### Out of memory errors
- Even though this is a minimal setup, ensure your cluster has sufficient memory
- Consider reducing replica counts further if needed

### Cannot access services
- Verify port forwarding is active
- Check service status: `kubectl get svc -n camunda`

## Related Profiles

- [`../minimal`](../minimal): Minimal configuration with persistence
- [`../development`](../development): Development configuration with more features
- [`../default`](../default): Standard configuration with full features

For more information about Camunda 8 Helm Profiles, see the [main README](../README.md).
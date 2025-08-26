# Shared Camunda Values Directory

This directory contains reusable Helm values files that can be composed together to create different Camunda Platform 8 configurations. Each file provides a specific configuration aspect that can be mixed and matched across different profiles.

## Purpose

The `camunda-values.d` directory serves as a shared library of configuration components that:

- **Promote reusability**: Common configurations are defined once and reused across multiple profiles
- **Enable composition**: Different profiles can combine multiple values files to achieve their desired configuration
- **Simplify maintenance**: Updates to shared configurations automatically benefit all profiles that use them
- **Provide modularity**: Each file focuses on a specific aspect (size, persistence, features, etc.)

## Available Configuration Files

### Cluster Sizing
- **[`cluster-size-mini.yaml`](cluster-size-mini.yaml)**: Minimal resource allocation suitable for development and testing
- **[`cluster-size-mini-dual-region.yaml`](cluster-size-mini-dual-region.yaml)**: Minimal dual-region configuration

### Persistence Options
- **[`persistence-in-memory.yaml`](persistence-in-memory.yaml)**: Configures Zeebe to use in-memory storage (no data persistence)

### Feature Toggles
- **[`elasticsearch-disabled.yaml`](elasticsearch-disabled.yaml)**: Disables Elasticsearch and dependent components (Operate, Tasklist, Optimize)
- **[`elasticsearch-only.yaml`](elasticsearch-only.yaml)**: Enables only Elasticsearch without other Camunda components
- **[`elasticsearch-2.5-region-stretch-cluster.yaml`](elasticsearch-2.5-region-stretch-cluster.yaml)**: Elasticsearch configuration for multi-region setups
- **[`elasticsearch-version.yaml`](elasticsearch-version.yaml)**: Specific Elasticsearch version configuration
- **[`identity-disabled.yaml`](identity-disabled.yaml)**: Disables Camunda Identity service
- **[`connectors-disabled.yaml`](connectors-disabled.yaml)**: Disables Camunda Connectors
- **[`connectors-outbound-only.yaml`](connectors-outbound-only.yaml)**: Enables only outbound connectors

### Infrastructure Settings
- **[`pod-anti-affinity-disabled.yaml`](pod-anti-affinity-disabled.yaml)**: Allows pods to be scheduled on the same nodes
- **[`ingress.yaml`](ingress.yaml)**: Standard ingress configuration
- **[`dual-region.yaml`](dual-region.yaml)**: Multi-region deployment settings

### Monitoring & Debugging
- **[`prometheus-service-monitor.yaml`](prometheus-service-monitor.yaml)**: Enables Prometheus ServiceMonitor for metrics collection
- **[`zeebe-debug.yaml`](zeebe-debug.yaml)**: Debug settings for Zeebe brokers

## Usage Example

The [`minimal-composed`](../minimal-composed) profile demonstrates how to compose multiple values files:

```makefile
chartValues ?= \
       "../camunda-values.d/cluster-size-mini.yaml" \
    -f "../camunda-values.d/persistence-in-memory.yaml" \
    -f "../camunda-values.d/elasticsearch-disabled.yaml" \
    -f "../camunda-values.d/identity-disabled.yaml" \
    -f "../camunda-values.d/connectors-disabled.yaml" \
    -f "../camunda-values.d/pod-anti-affinity-disabled.yaml" \
    -f "../camunda-values.d/prometheus-service-monitor.yaml" \
    -f "camunda-values.yaml"
```

This configuration creates a minimal, in-memory Camunda setup by combining:
- Mini cluster sizing
- In-memory persistence
- Disabled optional components
- Prometheus monitoring

## Creating New Profiles

To create a new profile using these shared values:

1. Create a new directory for your profile (e.g., `../my-profile/`)
2. Create a `config.mk` file that references the desired values files from this directory
3. Add any profile-specific overrides in a local `camunda-values.yaml` file
4. Use relative paths: `"../camunda-values.d/filename.yaml"`

Example `config.mk` structure:
```makefile
chartValues ?= \
       "../camunda-values.d/cluster-size-mini.yaml" \
    -f "../camunda-values.d/your-choice.yaml" \
    -f "camunda-values.yaml"
```

## File Naming Conventions

Files follow these naming patterns:
- **Component-specific**: `{component}-{setting}.yaml` (e.g., `elasticsearch-disabled.yaml`)
- **Feature-based**: `{feature}.yaml` (e.g., `ingress.yaml`, `dual-region.yaml`)
- **Size-related**: `cluster-size-{size}.yaml` (e.g., `cluster-size-mini.yaml`)

## Best Practices

1. **Order matters**: List values files from most general to most specific
2. **Local overrides**: Always include a local `camunda-values.yaml` file last for profile-specific customizations
3. **Modularity**: Keep each file focused on a single concern
4. **Documentation**: Include comments in YAML files explaining the purpose and impact
5. **Testing**: Test combinations to ensure they work together without conflicts
6. **Array merging limitation**: ⚠️ **Important**: Helm cannot merge arrays like `zeebe.env` - the last file with an array will completely override previous arrays. If multiple files need to set environment variables, consolidate them into a single file or use the final `camunda-values.yaml` file for all array-based configurations.

## Contributing

When adding new shared values files:

1. **Use descriptive names** that clearly indicate the file's purpose
2. **Add comments** explaining what the configuration does and when to use it
3. **Consider compatibility** with existing files
4. **Update this README** to document the new file
5. **Test with existing profiles** to ensure no breaking changes

## Related Documentation

- [Main Helm Profiles README](../README.md)
- [Minimal Composed Profile](../minimal-composed/README.md)
- [Camunda Platform Helm Chart Documentation](https://docs.camunda.io/docs/self-managed/platform-deployment/helm-kubernetes/)

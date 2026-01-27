# Camunda 8 with External Postgres

This helps to configure an environment with Camunda 8.8 environment where Keycloak, Management Identity and WebModeler 
use an external Postgres database  

## Features

This profile provides:
- **Keycloak**: Provision Keycloak pointing to an external Postgres database
- **Management Identity**: Configured to use the external Postgres database
- **WebModeler**: Configured to use the external Postgres database
- **Orchestration**: Configured to use Keycloak oidc for authentication
- **Elasticsearch**: for orchestration secondary storage
- **Connectors**: Configured to use Keycloak for m2m authentication

## Prerequisites

- An existing Kubernetes cluster using Kind, Google, AWS or Azure, etc
- A Postgres database accessible from the cluster (see the `aws/eks-and-aurora-postgres` recipe for an example)
- `kubectl` configured to connect to your cluster
- `helm` version 3.7.0 or later
- GNU `make`

## Helm values file

Run `make camunda-values.yaml` to generate a `camunda-values.yaml` file. 

## Install

```bash
make
```

## Verify Installation

Check that all pods are running:

```bash
make pods
```

Access the services by starting port forwarding. You will need to port forward to multiple services: 

```bash
make port-keycloak
```

```shell
make port-identity
```

```shell
make port-orchestration
```

```shell
make port-modeler
```

Then access:
- Keycloak: http://localhost:18081/auth
- Web Modeler: http://localhost:8070
- Operate UI: http://localhost:8080/orchestration/operate
- Tasklist UI: http://localhost:8080/orchestration/tasklist

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
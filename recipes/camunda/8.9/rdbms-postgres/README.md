# Camunda 8 with External Postgres

Sample of how to configure 8.9 with Postgres for RDBMS storage.

## Features

This profile provides:
- **Orchestration Cluster**: Configured to use external postgresql database as secondary storage

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

```shell
make port-orchestration
```

Then access:
- Web Modeler: http://localhost:26500
- Operate UI: http://localhost:8080/orchestration/operate
- Tasklist UI: http://localhost:8080/orchestration/tasklist

## Uninstall

```bash
make clean
```

This will remove the Camunda installation and clean up all resources.

## Use Cases

This profile is good to understand how to configure Camunda 8.9 with rdbms for secondary storage

## Limitations

⚠️ **Important**: This is provided for reference and learning, however it is **not suitable for production** use because:

- **No ingress**: There is no ingress controller, or dns, or network routing configured
- **No high availability**: Single instances of all components

## Customization

To customize this profile:

1. Edit [`my-camunda-values.yaml`](my-camunda-values.yaml) for additional overrides
2. Modify `config.mk` at the root project to ovverride default settings found in config.mk
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
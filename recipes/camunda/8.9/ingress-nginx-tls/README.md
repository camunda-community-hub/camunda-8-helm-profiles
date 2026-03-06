# Camunda 8 with External Postgres

Sample of how to configure 8.9 with nginx ingress and tls.

## Example Helm Command: 

```shell
helm upgrade --install --namespace camunda camunda /Users/dave/code/camunda-platform-helm/charts/camunda-platform-8.9 \
-f ./camunda-values.yaml --version 14.0.0-alpha4 --skip-crds
```

## Features

This profile provides:
- **Orchestration Cluster**: Configured to use nginx ingress with TLS

## Prerequisites

- An existing Kubernetes cluster using Kind, Google, AWS or Azure, etc
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

## Uninstall

```bash
make clean
```

This will remove the Camunda installation and clean up all resources.

## Use Cases

This profile is good to understand how to configure Camunda 8.9 with nginx ingress and tls for network access

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
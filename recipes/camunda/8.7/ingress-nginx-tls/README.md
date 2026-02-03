# Camunda 8.7 with Ingress and TLS

## Features

This profile provides a full Camunda 8 installation with ingress and tls

## Prerequisites

- An existing Kubernetes cluster using Kind, Google, AWS or Azure, etc
- `kubectl` configured to connect to your cluster
- `helm` version 3.7.0 or later
- GNU `make`
- The Camunda Platform Helm Chart (can be downloaded by running `make chart`)
- The Kubernetes namespace `camunda` (configured in [`config.mk`](config.mk) and created by running `make namespace`)

## Configuration

The profile uses the following configuration files:

- [`config.mk`](config.mk): Defines chart version, namespace, and values files to include
- [`mycamunda-values.yaml`](camunda-values.yaml): Additional custom overrides (minimal by design)
- Shared values from `../camunda-values.yaml.d/`:
  - `ingress-nginx-tls.yaml`: Config for ingress nginx and tls certificates

## Install

```bash
make
```

## Verify Installation

Check that all pods are running:

```bash
make pods
```

Access the services:

## Uninstall

```bash
make clean
```

This will remove the Camunda installation and clean up all resources.

## Limitations

⚠️ **Important**: This configuration is **not suitable for production** use because:

- **No high availability**: Single instances of all components

# Misc

```shell
 global.identity.auth.connectors.existingSecret.name
 global.identity.auth.operate.existingSecret.name
 global.identity.auth.tasklist.existingSecret.name
 global.identity.auth.optimize.existingSecret.name
 global.identity.auth.zeebe.existingSecret.name
 identityKeycloak.auth.existingSecret
 identityKeycloak.postgresql.auth.existingSecret
 postgresql.auth.existingSecret
 webModeler.restapi.mail.existingSecret.name
```

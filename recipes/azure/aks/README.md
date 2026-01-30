# Provision Azure AKS Kubernetes Cluster
This will provision an Azure AKS cluster. 

This recipe also includes optional targets for setting up an NGINX Ingress Controller, LetsEncrypt cert-manager, and cert-issuer for TLS support.

## Prerequisites
- An Azure account with permissions to create Azure AKS cluster.
- [Azure Command Line Interface (az)](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured.
```shell
$> make check-az
Checking Azure CLI configuration...
✅ Azure CLI is installed and connected to: Pay-as-you-go-Presales-Consulting PODE2422
```

- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.
- [eksctl](https://eksctl.io/) installed.

## Install
```sh
make
```

## Uninstall
```sh
make clean
```


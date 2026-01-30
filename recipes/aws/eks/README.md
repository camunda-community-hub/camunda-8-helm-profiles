# Provision AWS EKS Kubernetes Cluster
This will provision an AWS EKS cluster. 

This recipe also includes optional targets for setting up an NGINX Ingress Controller, LetsEncrypt cert-manager, and cert-issuer for TLS support.

## Prerequisites
- An AWS account with permissions to create EKS clusters
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
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


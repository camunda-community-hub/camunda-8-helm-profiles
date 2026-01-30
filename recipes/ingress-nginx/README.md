# Provision nginx ingress

Sets up an ingress-nginx controller. 

This example is configured to interact with a Google Kubernetes Engine (GKE) cluster, but can be adapted to other Kubernetes environments.

This recipe is very basic and really not that useful on its own. The recipes for setting up Azure AKS, AWS EKS, and GCP GKE clusters also include this same ability to provision a nginx ingress controller. 

After provisioning an ingress controller, you can optionally setup a cert-manager and cert-issuer for TLS support using Let's Encrypt.

## Prerequisites
- A Kubernetes cluster provisioned and accessible.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.

## Install
```sh
make
```

## Uninstall
```sh
make clean
```


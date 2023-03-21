# Camunda 8 Helm Profile: Ingress NGINX for Azure with TLS Certificates

A configuration for Camunda Platform 8
that uses [NGINX](https://www.nginx.com/products/nginx-ingress-controller/)
as an [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

This also configures Camunda to use an existing Domain Name. If you don't have a dns name yet, go one directory level up :-) 

This folder contains a [Helm](https://helm.sh/) [values file](camunda-values.yaml)
for installing the [Camunda Platform Helm Chart](https://helm.camunda.io/)
on an existing Azure AKS cluster (if you don't have one yet,
see [Kubernetes Installation for Camunda 8 on Azure](../../../../README.md)).
A [Makefile](Makefile) is provided to automate the installation process.
![Camunda 8 and NGINX](../../../../../ingress-nginx/Camunda%208%20and%20Nginx.png)

## Installation

If this is your first time here, make sure you have [installed the prerequisites](../../../../README.md).

After you've installed the prerequisites, follow these steps:

Open a Terminal and cd to `azure/ingress/nginx/tls` directory. 

Edit the [Makefile](Makefile) found in this directory and set the following bash variables so that they are appropriate for your specific environment.

If you don't have a Kubernetes cluster, the values provided will be used to create a new cluster. Otherwise, the values are used to connect and manage an existing cluster.

```
region ?= eastus
clusterName ?= MY_CLUSTER_NAME
resourceGroup ?= MY_CLUSTER_NAME-rg
# This dnsName value should be something similar to this: camunda.my.domain.com
dnsName ?= MY_DOMAIN_NAME
machineType ?= Standard_A8_v2
minSize ?= 1
maxSize ?= 6
certEmail ?= YOUR_EMAIL@camunda.com
```

If you need to create a new AKS Cluster, run `make kube`.

> **Note** By default, the vCPU Quota is set to 10 but if your cluster requires
> more than 10 vCPUS. You may need to go to the Quotas page and request an increase in the vCPU quota for the
> machine type that you choose.

Once you have a AKS Cluster, run `make` to do the following:

1. Set up a Kubernetes letsencrypt certificate manager
2. Install a Kubernetes Nginx Ingress Controller. A corresponding Load Balancer is provisioned automatically
3. Attempt to find the ip address of the Load Balancer. This ip address is then used generate a `camunda-values.yaml` file.
4. Helm is used to install Camunda 8 using the `camunda-values.yaml` file with the Load Balancer IP Address
5. The ingress controller is annotated so that letsencrypt tls certificates are provisioned.

You can re-install this profile easily. First run `make clean` to remove all kubernetes objects created by `make`. Then, re-run `make` to re-install.

WARNING!!! This will completely destroy your cluster and everything inside of it!!! To completely delete your cluster, run `make clean-kube`.

See the main README for [Troubleshooting, Tips, and Tricks](../../../../../README.md#troubleshooting-tips-and-tricks)
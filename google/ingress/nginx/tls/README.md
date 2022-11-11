# Camunda 8 Helm Profile: Ingress NGINX for GCP with TLS Certificates

A configuration for Camunda Platform 8
that uses [NGINX](https://www.nginx.com/products/nginx-ingress-controller/)
as an [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

This folder contains a [Helm](https://helm.sh/) [values file](camunda-values.yaml)
for installing the [Camunda Platform Helm Chart](https://helm.camunda.io/)
on an existing GKE cluster (if you don't have one yet,
see [Kubernetes Installation for Camunda 8 on GCP](../../../README.md)).
A [Makefile](Makefile) is provided to automate the installation process.

![Camunda 8 and NGINX](../../../../ingress-nginx/Camunda%208%20and%20Nginx.png)

## Installation

If this is your first time here, make sure you have [installed the prerequisites](../../../README.md).

After you've installed the prerequisites, follow these steps:

Open a Terminal and `cd` into this directory

Edit the [Makefile](Makefile) found in this directory and set the following bash variables so that they are appropriate for your specific environment.

If you don't have a Kubernetes cluster, the values provided will be used to create a new cluster. Otherwise, the values are used to connect and manage an existing cluster. 

```
project ?= camunda-researchanddevelopment
region ?= us-east1-b # see: https://cloud.withgoogle.com/region-picker/
clusterName ?= CLUSTER_NAME
# Azure provides temporary dns names such as: MY_DOMAIN_NAME.region.cloudapp.azure.com
# However GCP does not. DNS names will be configured using https://nip.io
# dnsLabel ?= MY_DOMAIN_NAME
machineType ?= n1-standard-16
minSize ?= 1
maxSize ?= 6
certEmail ?= YOUR_EMAIL@yourdomain.com
```

If you need to create a new GKE Cluster, run `make kube`. 

Once you have a GKE Cluster, run `make` to do the following:

1. Set up a Kubernetes letsencrypt certificate manager
2. Install a Kubernetes Nginx Ingress Controller. A corresponding GCP Load Balancer is provisioned automatically
3. Attempt to find the ip address of the Load Balancer. This ip address is then used generate a `camunda-values.yaml` file. 
4. Helm is used to install Camunda 8 using the `camunda-values.yaml` file with the Load Balancer IP Address
5. The ingress controller is annotated so that letsencrypt tls certificates are provisioned. 

You can re-install this profile easily. First run `make clean` to remove all kubernetes objects created by `make`. Then, re-run `make` to re-install.

WARNING!!! This will completely destroy your cluster and everything inside of it!!! To completely delete your cluster, run `make clean-kube`.

See the main README for [Troubleshooting, Tips, and Tricks](../../../../README.md#troubleshooting-tips-and-tricks)
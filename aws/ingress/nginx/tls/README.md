# Camunda 8 Helm Profile: Ingress NGINX for AWS EKS

A configuration for Camunda Platform 8
that uses [NGINX](https://www.nginx.com/products/nginx-ingress-controller/)
as an [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

This folder contains a [Helm](https://helm.sh/) [values file](camunda-values.yaml)
for installing the [Camunda Platform Helm Chart](https://helm.camunda.io/)
on an existing AWS EKS cluster (if you don't have one yet,
see [Kubernetes Installation for Camunda 8 on AWS](../../../README.md)).
A [Makefile](Makefile) is provided to automate the installation process.

![Camunda 8 and NGINX](../../../../ingress-nginx/Camunda%208%20and%20Nginx.png)

## Installation

If this is your first time here, make sure you have [installed the prerequisites](../../../README.md).

After you've installed the prerequisites, follow these steps: 

Open a Terminal and `cd` into this directory.

Edit the [Makefile](Makefile) found in this directory and set the following bash variables so that they are appropriate for your specific environment.

If you don't have a Kubernetes cluster, the values provided will be used to create a new cluster. Otherwise, the values are used to connect and manage an existing cluster.

```
region ?= us-east-1
zones ?= ['us-east-1a', 'us-east-1b']
clusterName ?= CLUSTER_NAME
machineType ?= c6i.4xlarge
# TODO: Currently, auto scaling configuration using these scripts for AWS is not working
# desiredSize is used as the starting size of the cluster
desiredSize ?= 3
minSize ?= 1
maxSize ?= 6
certEmail ?= YOUR_EMAIL@camunda.com
```

> :information_source: **Note** Currently autoscaling for AWS is not working yet. For now, desiredSize is used to set
> the starting size of the cluster

If you need to create a new EKS Cluster, run `make kube`

> :information_source: **Warning** Persistent volumes will fail on AWS EKS version 1.23 unless the [EBS CSI Driver Addon](https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html) is installed and configured correctly

If you need the EBS CSI Driver Addon, run the following: 

```shell
make ebs-csi-controller-addon
```

Once you have a EKS Cluster, run `make` to do the following:

1. Set up a Kubernetes letsencrypt certificate manager
2. Installs a Kubernetes Nginx Ingress Controller. A corresponding AWS Load Balancer is provisioned automatically
3. Scripts used by the `Makefile` will attempt to find the ip address of the Load Balancer. This ip address is then used generate a `camunda-values.yaml` file.
4. Helm is used to install Camunda 8 using the `camunda-values.yaml` file with the Load Balancer IP Address
5. The ingress controller is annotated so that letsencrypt tls certificates are provisioned.

You can re-install this profile easily. First run `make clean` to remove all kubernetes objects created by `make`. Then, re-run `make` to re-install.

WARNING!!! This will completely destroy your cluster and everything inside of it!!! To completely delete your cluster, run `make clean-kube`.

See the main README for [Troubleshooting, Tips, and Tricks](../../../../README.md#troubleshooting-tips-and-tricks)

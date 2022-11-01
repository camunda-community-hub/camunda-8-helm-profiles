# Camunda 8 Helm Profile: Azure Nginx Ingress with TLS

This folder contains scripts, a [Helm](https://helm.sh/) [values file](camunda-values.yaml), and a `Makefile` to help with the following: 

- create a AKS Cluster (if you don't have one yet)
- setup TLS and an nginx ingress
- install Camunda
- Networking is configured to use a single domain with seperate context paths for each application

## Prerequisites

Make sure you meet [these prerequisites](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/azure/README.md)

## Configure

Update the [Makefile](Makefile). Edit the bash variables so that they are appropriate for your specific environment.

If you already have a AKS Cluster, set these values to match your existing environment. Otherwise, these values will be used to create a new AKS Cluster:  

    region ?= eastus
    clusterName ?= <YOUR CLUSTER NAME>
    machineType ?= Standard_A8_v2
    minSize ?= 1
    maxSize ?= 6
    resourceGroup ?= <YOUR GROUP NAME>

## Create AKS Cluster

If you don't have an AKS Cluster yet, use the `Makefile` to create the cluster. 

> **Note** By default, the vCPU Quota is set to 10 but if your cluster requires
> more than 10 vCPUS. You may need to go to the Quotas page and request an increase in the vCPU quota for the
> machine type that you choose.

Open a terminal inside the same directory as this [README](README.md) file, then run:

```shell
make kube
```

If all goes well, you should be able to navigate to the Azure Console and see your newly created AKS cluster. 

## Install into existing Cluster

Open a terminal inside the same directory as this [README](README.md) file, then run:

```shell
make
```

This will setup an nginx ingress controller, setup TLS certificates and install Camunda.

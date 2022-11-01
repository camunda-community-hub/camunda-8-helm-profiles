# Camunda 8 Helm Profile: Azure App Gateway Ingress (no TLS)

This folder contains scripts, a [Helm](https://helm.sh/) [values file](camunda-values.yaml), and a `Makefile` to help with the following:

- create a AKS Cluster (if you don't have one yet)
- configure a [Camunda Helm](https://helm.sh/) [values file](camunda-values.yaml) to use app gateway ingress
- install Camunda 
- Networking is configured to use multiple domains using [this technique](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/README.md#networking)

## Prerequisites

Make sure you meet [these prerequisites](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/azure/README.md)

## Configure

Update the [Makefile](Makefile). Edit the bash variables so that they are appropriate for your specific environment.

If you already have a AKS Cluster, set these values to match your existing environment. Otherwise, these values will be used to create a new AKS Cluster:

    region ?= eastus
    clusterName ?= MY_CLUSTER_NAME
    resourceGroup ?= MY_CLUSTER_NAME-rg
    dnsLabel ?= MY_DOMAIN_NAME
    machineType ?= Standard_A8_v2
    minSize ?= 1
    maxSize ?= 6

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



# Azure Ingress

If you don't have an Azure Kubernetes Cluster yet, then [start here](https://github.com/camunda-community-hub/camunda8-greenfield-installation/tree/main/azure)

If you already have an Azure kubernetes cluster, but have not yet installed Camunda 8 and/or an ingress, or you would like to re-install Camunda 8 and ingress, then you're in the right place. 

This folder contains a makefile with targets to help set up a Camunda 8 environment and an Ingress controller into an existing Azure Kubernetes Cluster.

> Note that as a prerequisite to using these makefile targets, you should already have the Azure Client Tool (`az`) installed and ready to use.

## Install

Edit the `Makefile` inside this directory and set the variables as appropriate for your Azure environment.

To install a full Camunda 8 environment with ingress, simply run the following from this directory:  

```sh
make
```

Or, it's also possible to run make targets individually as needed. For example, to create the ingress (without installing Camunda) use:

```shell
make ingress-azure
# and
make clean-ingress-azure
```

If `make` is correctly configured, you should also get tab completion for all available make targets.

## Uninstall

When you're ready to remove the ingress and Camunda 8 components, run:

```sh
make clean
```

(note that this will keep the Kubernetes Cluster intact)

## Troubleshooting

### Debug logging for Identity
```yaml
identity:
  env:
   - name: LOGGING_LEVEL_ROOT
     value: DEBUG
```

### Keycloak requires SSL for requests from publicly routed IP addresses

> Users can interact with Keycloak without SSL so long as they stick to private IP addresses like localhost, 127.0.0.1, 10.x.x.x, 192.168.x.x, and 172.16.x.x. If you try to access Keycloak without SSL from a non-private IP address you will get an error.

If your Kubernetes cluster does not use "private" IP addresses for internal communication, i.e. it does not resolve the internal service names to "private" IP addresses, then the first time you attempt to authenticate to keycloak, you may encounter the following error:

![Keycloak ssl required](../../docs/images/keycloak_ssl_required.png?raw=true)

In order to address this issue, make sure the target *config-keycloak* completed successfully.
You can repeatedly run ```make config-keycloak``` without having to clean the installation and start over.

### Keycloak Admin password is incorrect
To retrieve the admin pasword from the secret adnd decode it you can run:  
 ```make keycloak-password```
 
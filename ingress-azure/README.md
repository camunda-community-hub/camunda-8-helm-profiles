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

![Keycloak ssl required](../docs/images/keycloak_ssl_required.png?raw=true)

In order to address this issue, make sure the target *config-keycloak* completed successfully.
You can repeatedly run ```make config-keycloak``` without having to clean the installation and start over.

### Keycloak Admin password is incorrect
To retrieve the admin pasword from the secret adnd decode it you can run:  
 ```make keycloak-password```
 
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

In order to address this issue, we first need temporary access to keycloak. We can accomplish this using Kubernetes port forwarding. Run the following command to temporarily establish port forward from localhost to port 18080.

     make port-keycloak

Now, you should be able to browse to `http://localhost:18080`. By default, the username is `admin` and password is `camunda`.

The steps to fix this are described [here](https://docs.camunda.io/docs/self-managed/identity/troubleshooting/common-problems/#solution-2-identity-making-requests-from-an-external-ip-address). In the Keycloak UI 
- On the top left switch to the *Master* realm if needed.
- In the Configure ection in the menu on the left, navigate to *Realm Settings*, then choose the *Login* tab.
- Set "Require SSL" to "none"  
Perform those steps for **both** the **Master** realm (Keycloak needs a restart after that) and the then created **Camunda Platform** realm. We did an Identity restart afterwards, e.g. by deleting the pod, but it should also work if the crash loop does one more round.

### Keycloak Admin password is incorrect
To retrieve the admon pasword from the secret adnd decode it you can run:  
 ```kubectl get secret camunda-keycloak -o yaml | grep admin | awk '{print $2}' | base64 -d```
 
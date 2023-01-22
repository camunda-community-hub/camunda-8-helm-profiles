# Camunda 8 Helm Profile: Keycloak

This folder contains a [Makefile](Makefile) that can be used to install and configure Keycloak into an existing Kubernetes Cluster.

If you don't have a Kubernetes Cluster yet, see the main [README](../README.md) for details on how to create a cluster on the popular cloud providers.

Note that by default, the Camunda Helm charts will install and configure Keycloak automatically. However, sometimes 
customers would like to use an existing Keycloak.

These scripts help with setting up a standalone Keycloak accessible over https with valid tls certificates. This is convenient for
testing Camunda Helm scripts against an existing, "external", Keycloak.

The [google external keycloak profile](../google/external-keycloak) helps to install Camunda to point to an existing, external Keycloak. So, once you're done here and have a running cluster with Keycloak, you might be interested in using the [google external keycloak profile](../google/external-keycloak) to configure Camunda in a separate cluster (pointing to the Keycloak you set up here).

## Install

Make sure you meet [these prerequisites](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/README.md#prerequisites).

Open a terminal, cd to this directory, and edit the [Makefile](./Makefile) and change the parameters as needed. At the very least, replace the following: `KEYCLOAK_HOSTNAME`, `CLUSTER_NAME`, `YOUR_EMAIL@yourdomain.com`

Then run:

```sh
make
```

If all make targets run successfully, the following will be installed:  

1. A Kubernetes [cert-manager](https://cert-manager.io/)
2. [Lets Encrypt](https://letsencrypt.org/) [staging](https://letsencrypt.org/docs/staging-environment/) [ClusterIssuer](https://cert-manager.io/docs/concepts/issuer/).
3. A nginx [Kubernetes Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
4. A Keycloak instance configured with ingress rules and valid tls certificate from lets encrypt staging environment.  

If needed, run the following to port forward to the keycloak service:

```shell
make port-keycloak
```

If needed, run the following to see the admin password: 

```shell
make keycloak-password
```

Then, access keycloak over https://YOUR_KEYCLOAK_HOSTNAME

## Uninstall
```sh
make clean
````


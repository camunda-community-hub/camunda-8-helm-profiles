# Camunda 8 Helm Profile: Keycloak

It's often a requirement to configure Camunda to connect to an existing, external Keycloak. The scripts in this direct help to do so. 

This directory contains 2 Helm Profiles that are useful for configuring the following: 

1. This [keycloak](./) directory contains scripts to create a kubernetes cluster with a standalone keycloak accessible over tls/https. 
2. The [camunda](camunda) subdirectory contains scripts to create a separate kubernetes cluster containing the Camunda 8 Platform configured to [connect to an existing, external Keycloak instance](https://docs.camunda.io/docs/self-managed/platform-deployment/helm-kubernetes/guides/using-existing-keycloak/)

If you'd rather have Camunda Helm charts install Keycloak for you, you probably want to use the [tls profile](../ingress/nginx/tls) instead. 

As mentioned above, this folder contains a [Makefile](Makefile) to automate the installation process of a kubernetes cluster serving Keycloak over tls/https. If you already have your own Keycloak installed, then go to the [camunda](camunda) subfolder for help to install the Camunda 8 Platform to connect to your existing Keycloak.

## Installation

If this is your first time here, make sure you have [installed the prerequisites](../../../README.md).

After you've installed the prerequisites, follow these steps:

Open a terminal, cd to this directory, and edit the [Makefile](./Makefile) and change the parameters as needed. At the very least, replace the following: `CLUSTER_NAME` and `YOUR_EMAIL@yourdomain.com`. 

If you don't have a Kubernetes cluster, the values provided will be used to create a new cluster. Otherwise, the values are used to connect and manage an existing cluster.

If you need to create a new GKE Cluster, run `make kube`.

Note that by default, this will use `keycloak-values-ip` to create a values file using the IP address of the ingress controller and the nip.io service. As an advanced option, you can define a hostname by using the `keycloak-values-hostname` target (and setting `KEYCLOAK_HOSTNAME` in the `Makefile`) 

Once you have a GKE Cluster, run `make` to do the following:

1. Install a Kubernetes [cert-manager](https://cert-manager.io/)
2. Setup a [Lets Encrypt](https://letsencrypt.org/) [staging](https://letsencrypt.org/docs/staging-environment/) [ClusterIssuer](https://cert-manager.io/docs/concepts/issuer/).
3. Install a nginx [Kubernetes Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
4. Install a Keycloak instance configured with ingress rules and valid tls certificate from lets encrypt staging environment.

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

WARNING!!! This will completely destroy your cluster and everything inside of it!!! To completely delete your cluster, run `make clean-kube`.

See the main README for [Troubleshooting, Tips, and Tricks](../../README.md#troubleshooting-tips-and-tricks)
# Camunda 8 Helm Profile: Install Camunda with Existing Keycloak

A configuration for Camunda Platform 8
that uses [NGINX](https://www.nginx.com/products/nginx-ingress-controller/)
as an [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/) and [Let's Encrypt](https://letsencrypt.org/) to provision certificates. 

In addition, this profile will configure Camunda Platform 8 to [connect to an existing, external Keycloak instance](https://docs.camunda.io/docs/self-managed/platform-deployment/helm-kubernetes/guides/using-existing-keycloak/). A new `Camunda-platform` realm will be created and configured in your existing Keycloak.

If you don't yet have a Keycloak installation, you probably want to use the [Google ingress nginx tls profile](../../ingress/nginx/tls) instead. That way, the Camunda Helm charts will install Keycloak for you. 

This folder contains a [Makefile](Makefile) to help automate the installation process.

## Installation

If this is your first time here, make sure you have [installed the prerequisites](../../../README.md).

After you've installed the prerequisites, follow these steps:

Open a terminal, cd to this directory, and edit the [Makefile](./Makefile) and change the parameters as needed. At the very least, replace the following: `CLUSTER_NAME`, `YOUR_EMAIL@yourdomain.com`, and `KEYCLOAK_HOSTNAME` to point to your existing keycloak environment.

If you don't have a Kubernetes cluster, the values provided will be used to create a new cluster. Otherwise, the values are used to connect and manage an existing cluster.

Note that if you used [the keycloak profile](../README.md) to install Keycloak, the scripts in this directory should be run in a separate cluster than the one you used to install Keycloak.

If you need to create a new GKE Cluster, run `make kube`.

Once you have a GKE Cluster, run `make` to do the following:

1. Set up a Kubernetes letsencrypt staging certificate manager
2. Install a Kubernetes Nginx Ingress Controller. A corresponding GCP Load Balancer is provisioned automatically
3. Attempt to find the ip address of the Load Balancer. This ip address is then used generate a `camunda-values.yaml` file. 
4. A `camunda-values-ext-keycloak.yaml` will be generated with the appropriate Load Balancer IP Address. 
5. Helm is used to install Camunda 8 using the `camunda-values-ext-keycloak.yaml` file. Identity is configured to connect to the existing, external Keycloak.  
6. The ingress controller is annotated so that letsencrypt tls certificates are provisioned.

Note!!! It's often necessary to sign certificates with a custom Certificate Authority. This profile has an example of extra configuration needed if you use a Custom CA. This profile is using Let's Encrypt [Staging Environment](https://letsencrypt.org/docs/staging-environment/) to provision tls certificates. By default, these certificates will not be trusted by your browser or by the JVM. This [truststore](../../../include/cacerts_staging) contains all of the Certificate Authorities used by Let's Encrypt Staging certificates. When Camunda is installed, each of the webapps are setup to use this [truststore](../../../include/cacerts_staging).  

You can re-install this profile easily. First run `make clean` to remove all kubernetes objects created by `make`. Then, re-run `make` to re-install.

WARNING!!! This will completely destroy your cluster and everything inside of it!!! To completely delete your cluster, run `make clean-kube`.

See the main README for [Troubleshooting, Tips, and Tricks](../../README.md#troubleshooting-tips-and-tricks)
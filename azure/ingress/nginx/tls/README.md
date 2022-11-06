# Camunda 8 Helm Profile: Ingress NGINX for Azure with TLS Certificates

Open a Terminal and `cd` into this directory

Edit the [Makefile](Makefile) found in this directory and set the following bash variables so that they are appropriate for your specific environment.

If you don't have a Kubernetes cluster, the values provided will be used to create a new cluster. Otherwise, the values are used to connect and manage an existing cluster.

```
region ?= eastus
clusterName ?= MY_CLUSTER_NAME
resourceGroup ?= MY_CLUSTER_NAME-rg
# This dnsLabel value will be used like so: MY_DOMAIN_NAME.region.cloudapp.azure.com
dnsLabel ?= MY_DOMAIN_NAME
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

## Check TLS Certificates

To check to make sure that letsencrypt has successfully issued tls certs, use the following command:

```
kubectl get certificaterequest --all-namespaces
```


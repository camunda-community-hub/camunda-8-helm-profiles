# Camunda 8 Helm Profile: Ingress NGINX for GCP with TLS Certificates

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

## Check TLS Certificates

To check to make sure that letsencrypt has successfully issued tls certs, use the following command:

```
kubectl get certificaterequest --all-namespaces
```
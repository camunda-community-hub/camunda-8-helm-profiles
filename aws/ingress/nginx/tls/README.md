# Camunda 8 Helm Profile: Ingress NGINX for AWS EKS

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

If you need to create a new EKS Cluster, run `make kube`.

Once you have a EKS Cluster, run `make` to do the following:

1. Set up a Kubernetes letsencrypt certificate manager
2. Installs a Kubernetes Nginx Ingress Controller. A corresponding AWS Load Balancer is provisioned automatically
3. Scripts used by the `Makefile` will attempt to find the ip address of the Load Balancer. This ip address is then used generate a `camunda-values.yaml` file.
4. Helm is used to install Camunda 8 using the `camunda-values.yaml` file with the Load Balancer IP Address
5. The ingress controller is annotated so that letsencrypt tls certificates are provisioned.

## Check TLS Certificates

To check to make sure that letsencrypt has successfully issued tls certs, use the following command: 

```
kubectl get certificaterequest --all-namespaces
```

### Note about AWS Load Balancer domain name tls certs

AWS gives domain names for Load Balancers. We tried to configure letsencrypt to create certificates for these domain names, however, let's encrypt can only generate certs for domain names less than a certain length. It should be possible, but there is some work left to do.   

```
Message:               Failed to wait for order resource "tls-secret-ltx5k-1407422140" to become ready: order is in "errored" state: Failed to create Order: 400 urn:ietf:params:acme:error:rejectedIdentifier: NewOrder request did not include a SAN short enough to fit in CN
```
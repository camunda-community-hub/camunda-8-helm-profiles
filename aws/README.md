# Amazon Web Services Prerequisites

1. Verify `aws` command line tool is installed (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

       aws --help

2. Configure `aws` to connect to your account. If you don't already have one, you'll need to sign up for a new
   AWS Account. Use the following command to configure the `aws` tool to use your AWS Access Key ID and secret.

       $ aws configure

Double check you can connect by running the following

       $ aws iam get-account-summary

3. Verify `eksctl` is installed (https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)

       $ eksctl version

4. Use the AWS-specific `Makefile` to create a GKE cluster

`cd` into the `aws` directory

Edit the `./aws/Makefile` and set the following bash variables so that they are appropriate for your specific environment.

     clusterName ?= <YOUR CLUSTER NAME>
     region ?= us-east-1
     zones ?= ['us-east-1a', 'us-east-1b']
     machineType ?= m5.2xlarge
     minSize ?= 4

> :information_source: **Note** Currently autoscaling for AWS is not working yet. For now, minSize is also used to set
> the starting size of the cluster

5. Run `make` to create a new AKS Cluster and install Camunda

Note that the make file for `aws` will attempt to automatically find the IP address of the nginx ingress. For more details
see the section below which describes how to find the IP Address of the Load Balancer of your newly created EKS cluster.

6. Run `kubectl get ingress`. The Values listed in the `HOSTS` column will show the urls that can be used to access your environment

7. By default, Prometheus metrics and a Grafana Dashboard are also installed and configured. You can access this by running the following:

```shell
kubectl get service metrics-grafana-loadbalancer --namespace default
```

Copy the `EXTERNAL-IP` to access the Grafana Dashboard Web UI. The username and password can be found inside `./metrics/grafana-secret.yaml`

## EKS Load Balancer IP Address

When nginx ingress is installed in an EKS environment, AWS will create a Load Balancer.

To see details, try running the following command:

```shell
kubectl get service -n ingress-nginx
```

You should see output like the following. The EXTERNAL-IP is your load balancer's dns name

```shell
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.100.160.33    ac5770377baff43b7b35f28d725538eb-1410992827.us-east-1.elb.amazonaws.com   80:30114/TCP,443:31088/TCP   13m
ingress-nginx-controller-admission   ClusterIP      10.100.229.127   <none>                                                                    443/TCP                      13m
```

Alternatively, navigate to the "EC2 Dashboard" within the AWS console. Look on the left side bar and click on "Load Balancers".
You should find the dns name in the "Basic Configration" section of the screen.

This domain name is associated to multiple ip addresses, one IP address for each Availability Zone. To find the ip
addresses used by this domain, try `nslookup` on windows, or `dig` on mac or linux.

For example, on Windows:
```shell
nslookup ac5770377baff43b7b35f28d725538eb-1410992827.us-east-1.elb.amazonaws.com
```

Or on Mac/Linux:
```shell
dig +short ac5770377baff43b7b35f28d725538eb-1410992827.us-east-1.elb.amazonaws.com
```

The first IP Address is used to configure Camunda Ingress Rules. 

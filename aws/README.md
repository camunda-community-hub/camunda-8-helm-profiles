# Helm Profiles for Camunda 8 on Amazon Web Services (AWS)

Create a Camunda 8 self-managed Kubernetes Cluster in 3 Steps:

Step 1: Setup some [global prerequisites](../README.md#prerequisites)

Step 2: Setup command line tools for AWS:

1. Verify `aws` command line tool is installed (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

       aws --help

2. Configure `aws` to connect to your account. If you don't already have one, you'll need to sign up for a new
   AWS Account. Use the following command to configure the `aws` tool to use your AWS Access Key ID and secret.

       $ aws configure

Double check you can connect by running the following

       $ aws iam get-account-summary

3. Verify `eksctl` is installed (https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)

       $ eksctl version

4. Go into one of the profiles inside this `aws` folder and use the `Makefile` to create a EKS cluster.

e.g. `cd` into the `ingress/nginx/tls` directory and see the [README.md](./ingress/nginx/tls/README.md) for more.

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

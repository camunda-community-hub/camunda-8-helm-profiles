## In progress / Known Issues

### TODO: Fix development `standard` persistent volume type

Currently, the `camunda-values.yaml` in the development profile specifies a `standard` storage class for Kind but that 
breaks when deploying to the cloud. As a temp hack, there's a `camunda-values-2.yaml` with `ssd` storage class

### TODO: Fix issue with applying AWS ebs-csi addon

After the `create-ebs-csi-addon` target in [kuberenets-aws.mk](aws/include/kubernetes-aws.mk) file, you'll see an error
because there's no delay to allow the sa account to complete. 

To fix this, run `make annotate-ebs-csi-sa restart-ebs-csi-controller`

```shell
kubectl annotate serviceaccount ebs-csi-controller-sa \
-n kube-system \
eks.amazonaws.com/role-arn=arn:aws:iam::487945211782:role/AmazonEKS_EBS_CSI_DriverRole_Cluster_dave-camunda-01 \
--overwrite
Error from server (NotFound): serviceaccounts "ebs-csi-controller-sa" not found
make: *** [annotate-ebs-csi-sa] Error 1
```

## May 16, 2023

- Many improvements made in preparation for the Community Summit Workshop
- Updated profiles to use Camunda version 8.2.3 Helm Chart by default
- All non-tls profiles are using 8.2.3 of Camunda 8 Platform
- All tls profiles are using 8.3.0-alpha0 of Camunda 8 Platform
- Regression tested each cloud provider development profile
- Regression tested each cloud provider `ingress/nginx` profile
- Regression tested each cloud provider `ingress/nginx/tls` profile
- Enabled [Connectors](https://docs.camunda.io/docs/components/connectors/use-connectors/) in profiles
- Fixed Azure networking issue related to Azure Load Balancer Health Probes. We add /healthz to load balancer paths by default  
- The `deploy-models` target was moved out of the benchmark profile and refactored slightly to be more reusable. See examples inside [bpmn/deploy-models.mk](bpmn/deploy-models.mk)
- renamed `kube-nginx` target in azure profile to be kube-azure

## Before May 2023 Camunda v8.1.x, Helm Profiles 0.0.1

- This helm profile project existed since early 2022, but we did not start this CHANGELOG until May 2023. 
- Before then, Helm profiles supported Camunda version 8.1.x

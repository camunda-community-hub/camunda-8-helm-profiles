# Network troubleshooting

```shell


# Service
nslookup camunda-zeebe.camunda-eastus.svc.cluster.local
# Pod in same region
nslookup camunda-zeebe-0.camunda-zeebe.camunda-eastus.svc.cluster.local

# This can't 
# Pod in different region (IT WORKS!)
nslookup camunda-zeebe-0.camunda-zeebe.camunda-canadacentral.svc.cluster.local

# eastus dns
# 10.1.241.67
# 10.1.241.62
# canadacentral dns
# 10.2.241.42
# 10.2.241.13

kubectl -n kube-system rollout restart deployment coredns
kubectl get configmap coredns-custom -n kube-system -o yaml

   
```

# Prerequisites

## Install `istoctl`

Download from here: https://istio.io/latest/docs/setup/getting-started/#download

Run the following (I guess it connects using kubeconfig?)

```shell
istioctl install --set profile=demo -y
```

Label the namespace: 

```shell
kubectl label namespace camunda istio-injection=enabled
```

Install the demo application: 
```shell
kubectl apply -f bookinfo/platform/kube/bookinfo.yaml
```

Verify things are working: 
```shell
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
```

Setup gateway: 
```shell
kubectl apply -f bookinfo/networking/bookinfo-gateway.yaml
```

Find endpoint: 
```shell
kubectl get svc istio-ingressgateway -n istio-system
```

Test it out: 
[https://<endpoint>/productpage](https://<endpoint>/productpage)

How to view logs of sidecar proxy containers:
```shell
kubectl logs camunda-keycloak-0 -c istio-proxy -n camunda
```

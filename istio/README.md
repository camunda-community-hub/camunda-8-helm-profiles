# Helm Profile for configuring Istio

Istio Gateway and Virtual Services can be used as an alternative to nginx ingress. This directory contains yaml files 
and scripts to expose Camunda 8 Self Managed components using Istio. 

# Prerequisites

## Install `istoctl`

Download from here: https://istio.io/latest/docs/setup/getting-started/#download

# Install Istio Components

Run the following (I guess it connects using kubeconfig?)

```shell
istioctl install --set profile=demo -y
```
# Configure the Istio bookinfo demo app

Label the namespace:

```shell
kubectl label namespace camunda istio-injection=enabled
```

Install the demo application. The `bookinfo` demo application is downloaded when you install istioctl. You can use
`bookinfo` demo to verify that istio works in your kuberenetes environment:

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

# Configure the Camunda Environment to use Istio 

TODO: provide steps on how to configure camunda. Look in [istio.mk](istio.mk) file for steps. 

# Configuring Istio in a local kubernetes environment: 

https://github.com/jessesimpson36/tmp-camunda-istio

# Kind setup

This document describes a step-by-step guide to create a full Camunda 8 cluster with all Components, Ingress and TLS configuration. Run all commands in the exact order as described here.

## Prerequisites
Add the following entries in your /etc/hosts file
```
    127.0.0.1 zeebe.camunda.local
    127.0.0.1 camunda.local   
```

## Ensure your working directory is kind/manual-setup/8.8
```
   pwd
```


## Create a kind cluster with Ingress Controller (ingress-nginx)
```
    kind create cluster --name camunda-platform-local --config ./kind-cluster.config

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=90s

    kubectl get pods -n ingress-nginx
```
## Add Helm repo
```
    helm repo add camunda https://helm.camunda.io
    helm repo update
```

## Configure kubectl config
```
    kubectl config set-context --current --namespace camunda
```

## Create Secret with all required credentials

```
    kubectl create secret generic camunda-credentials \
      --from-literal=identity-console-client-token=camunda \
      --from-literal=identity-optimize-client-token=camunda \
      --from-literal=identity-orchestration-client-token=camunda \
      --from-literal=identity-connectors-client-token=camunda \
      --from-literal=identity-firstuser-password=camunda \
      --from-literal=identity-keycloak-postgresql-admin-password=camunda \
      --from-literal=identity-keycloak-postgresql-user-password=camunda \
      --from-literal=identity-keycloak-admin-password=camunda \
      --from-literal=webmodeler-postgresql-admin-password=camunda \
      --from-literal=webmodeler-postgresql-user-password=camunda \
      --namespace camunda
```

## TLS certificates

```
    cd ./SSL/
```
run all commands in [./SSL/openSslCommands.md](./SSL/openSslCommands.md)
```
    kubectl create secret tls camunda-tls --namespace camunda --key ./SSL/camunda-local-tls.key --cert ./SSL/camunda-local-tls.crt
```

## OPTIONAL pem file for Desktop Modeler  (if you do not want to import the new Root CA created with the previous step)
```
    openssl rsa -in ./SSL/camunda-local-tls.key -out ./SSL/camunda-local-tls.pem
```

## Install Camunda 8.8 with Ingress
```
    helm install camunda camunda/camunda-platform \
      --version 13.0.0 \
      --namespace camunda \
      -f ./values-local-ingress-8.8.yaml
```

## OPTIONAL Configure Desktop Modeler

  - Create a new Application in [Management Identity](https://camunda.local/identity) with name desktopmodeler
  - Authorize this client in [Orchestration Identity](https://camunda.local/orchestration/identity) to RESOURCE * with Create permission
  - Configure Desktop Modeler:
```
    Cluster Endpoint: https://camunda.local/orchestration
    Authentication: OAuth
    Client ID: desktopmodeler
    Client Secret: <copyFromManagementIdentity>
    OAuthTokenUrl: https://camunda.local/auth/realms/camunda-platform/protocol/openid-connect/token
    OAuth Audience: orchestration-api
```

## Delete installation

```
    helm uninstall camunda -n camunda
    kubectl delete pvc --all -n camunda
```
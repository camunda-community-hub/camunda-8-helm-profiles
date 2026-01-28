# Manage Keycloak

This is a recipe to help with managing Keycloak. 

## Create new temporary admin user

You must have a running keycloak pod in Kubernetes named `camunda-keycloak-0`

Set the appropriate variables inside config.mk (or set them in the global config.mk at the root of this project) and then run: 

```shell
make create-keycloak-admin-user
```

## Prerequisites
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.

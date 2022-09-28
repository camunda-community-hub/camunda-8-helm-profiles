# Camunda 8 Helm Profile: Ingress NGINX

A configuration for Camunda Platform 8
that uses [NGINX](https://www.nginx.com/products/nginx-ingress-controller/)
as an [Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/).

This folder contains a [Helm](https://helm.sh/) [values file](camunda-values.yaml)
for installing the [Camunda Platform Helm Chart](https://helm.camunda.io/)
on an existing Kubernetes cluster (if you don't have one yet,
see [Camunda 8 Kubernetes Installation](https://github.com/camunda-community-hub/camunda8-greenfield-installation)).
A [Makefile](Makefile) is provided to automate the installation process.

## Install
Configure the desired Kubernetes `namespace`, Helm `release` name, and Helm `chart` in [Makefile](Makefile)
and run:

```sh
make
```

If `make` is correctly configured, you should also get tab completion for all available make targets.

## Uninstall
```sh
make clean
```

## Troubleshooting

### Debug logging for Identity
```yaml
identity:
  env:
   - name: LOGGING_LEVEL_ROOT
     value: DEBUG
```

### Keycloak requires SSL for requests from publicly routed IP addresses

> Users can interact with Keycloak without SSL so long as they stick to private IP addresses like localhost, 127.0.0.1, 10.x.x.x, 192.168.x.x, and 172.16.x.x. If you try to access Keycloak without SSL from a non-private IP address you will get an error.

If your k8s cluster does not use "private" IP addresses for internal communication, i.e. it does not resolve the internal service names to "private" IP addresses, then you can apply the following procedure:

Use the Keycloak UI to set "Require SSL" to "none" for both the Master realm (Keycloak needs a restart after that) and the then created Camunda Platform realm. We did an Identity restart afterwards, e.g. by deleting the pod, but it should also work if the crash loop does one more round.

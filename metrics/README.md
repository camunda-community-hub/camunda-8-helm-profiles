# Camunda 8 Helm Profile: Metrics

This folder contains a [Makefile](Makefile) that can be used to install and configure Prometheus and Grafana into an existing Kubernetes Cluster. 

If you don't have a Kubernetes Cluster yet, see the main [README](../README.md) for details on how to create a cluster on the popular cloud providers.

## Install

Make sure you meet [these prerequisites](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/README.md#prerequisites).

Manually create a secret to store grafana admin credentials. Save the following to a file named `grafana-secret.yml` and then run `kubectl apply -f grafana-secret.yml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: grafana-admin-password
type: Opaque
stringData:
  admin-user: camunda
  admin-password: <your-secure-password>
```

Open a terminal and run:

```sh
make
```

If `make` is correctly configured, you should also get tab completion for all available make targets.

## Uninstall
```sh
make clean
```
# Grafana URL

After a succesful install, the following command can be used to see the Grafana Service: 

```shell
kubectl get service metrics-grafana-loadbalancer --namespace default
```

Copy the `EXTERNAL-IP` to access the Grafana Dashboard Web UI. The username and password can be found inside [grafana-secret.yml](grafana-secret.yml)


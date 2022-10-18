# Camunda 8 Helm Profile: Metrics

This folder contains a [Makefile](Makefile) that can be used to install and configure Prometheus and Grafana into an existing Kubernetes Cluster. (if you don't have one yet, see [Cloud-platform-specific Profiles](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/README.md#cloud-platform-specific-profiles)).

## Install

Make sure you meet [these prerequisites](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/README.md#prerequisites).

Open a terminal, and run:

```sh
make
```

If `make` is correctly configured, you should also get tab completion for all available make targets.

## Uninstall
```sh
make clean
```
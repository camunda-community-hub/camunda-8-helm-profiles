# Camunda 8 Helm Profile: Metrics

This folder contains a [Makefile](Makefile) that can be used to install and configure Prometheus and Grafana into an existing Kubernetes Cluster. 

## Features

This profile provides:
- **Prometheus**:  installed via the Prometheus Community Helm Chart
- **Grafana**: installed via the Prometheus Community Helm Chart

## Prerequisites

- An existing Kubernetes cluster using Kind, Google, AWS or Azure, etc
- `helm` version 3.7.0 or later
- GNU `make`

## Install

By default, the Grafana admin password is set inside [./config.mk](./config.mk). To override the default password,
Create a `config.mk` at the root of this project and override the `GRAFANA_PASSWORD` variable to set a custom Grafana admin password:

Open a terminal and run:

```sh
make
```
## Uninstall
```sh
make clean
```

# Grafana connection details:  

```shell
make url-grafana
```

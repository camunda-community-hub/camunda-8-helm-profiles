# Camunda 8 Helm Profile: Cloud Flare PKI Toolkit

> **Note**  This profile is still a work in progress. For latest progress, please see this [Github Issue](https://github.com/camunda-community-hub/camunda-8-helm-profiles/issues/41)

This folder contains a [Makefile](Makefile) that can be used to install and configure TLS Certificates using Cloud Flare's PKI Toolkit `cfssl`. 

If you don't have a Kubernetes Cluster yet, see the main [README](../README.md) for details on how to create a cluster on the popular cloud providers.

## Install

Make sure you meet [these prerequisites](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/README.md#prerequisites).

For this profile, you will also need the following:

1. `cfssl` command line tool
2. `jq` command line tool 

Open a terminal, and run:

```sh
make
```

## Uninstall
```sh
make clean
```
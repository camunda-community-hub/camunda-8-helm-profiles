# Helm Profile for Horizontally Scaling Tasklist

The Camunda 8 Tasklist webapp consists of 3 modules:
- Webapp
- Importer
- Archiver

This directory provides scripts that demonstrate how to horizontally scale Tasklist so that 1 instance of the importer/archiver, and 2 instances of the webapp are running. 

These scripts are not intended to be used in Production, they are for reference only. Feel free to copy and customize for your environment and your specific requirements. 

## Overview

1. Use the [Camunda 8 Helm Charts](https://github.com/camunda/camunda-platform-helm) to install a full environment (including tasklist)
2. Run the [make target](./include/tasklist.mk) `make tasklist-delete` to remove the existing configmap and deployment installed by the Camunda 8 Helm Charts
3. Edit the [yaml files](./include) and update them to be relevant for your existing kubernetes cluster and Camunda environment
4. Run the [make target](./include/tasklist.mk) `make tasklist-install` to use kubectl to apply the `*.yaml` files found in the [include](./include) directory

## Configuration Defaults

By default, the scripts and yaml files will setup a single tasklist importer/archiver instance and 2 tasklist webapps (without the importer/archiver). 

The files provided here are for reference only. These files will need to be modified with specifics for your environment.

Here's a table that shows some of the configurations that will need to be changed to match your specific environment and requirements: 

| Option                     | Default                 | Source File           |
|----------------------------|-------------------------|-----------------------|
| Version                    | latest                  | `deployment-*.yaml`   |
| Context Path               | /tasklist                | `deployment-*.yaml`   |
| Elasticsearch clusterName  | elasticsearch           | `configmap-*.yaml`    |
| Elasticsearch host         | elasticsearc-master     | `configmap-*.yaml`    |
| Elasticsearch port         | 9200                    | `configmap-*.yaml`    |
| Elasticsearch index prefix | zeebe-record            | `configmap-*.yaml`    |
| Many urls related to Auth  | See `deployment-*.yaml` | `deployment-*.yaml`   |

# Helm Profile for Horizontally Scaling Operate

> [!IMPORTANT]  
> This profile is deprecated, please use [high-available-webapps](../high-available-webapps) profile instead

The Camunda 8 Operate webapp [consists of 3 modules](https://docs.camunda.io/docs/self-managed/operate-deployment/importer-and-archiver/). 
- Webapp
- Importer
- Archiver

This directory provides scripts that demonstrate how to horizontally scale Operate so that 1 instance of the importer/archiver, and 2 instances of the webapp are running. 

These scripts are not intended to be used in Production, they are for reference only. Feel free to copy and customize for your environment and your specific requirements. 

## Overview

1. Use the [Camunda 8 Helm Charts](https://github.com/camunda/camunda-platform-helm) to install a full environment (including Operate)
2. Run the [make target](./include/operate.mk) `make operate-delete` to remove the existing configmap and deployment installed by the Camunda 8 Helm Charts
3. Edit the [yaml files](./include) and update them to be relevant for your existing kubernetes cluster and Camunda environment
4. Run the [make target](./include/operate.mk) `make operate-install` to use kubectl to apply the `deployment-*.yaml` and `configmap-*.yaml` files found in this directory

## Configuration Defaults

By default, the scripts and yaml files will setup a single Operate importer/archiver instance and 2 Operate webapps (without the importer/archiver). 

The files provided here are for reference only. These files will need to be modified with specifics for your environment.

Here's a table that shows some of the configurations that will need to be changed to match your specific environment and requirements: 

| Option                     | Default                 | Source File           |
|----------------------------|-------------------------|-----------------------|
| Version                    | latest                  | `deployment-*.yaml`   |
| Context Path               | /operate                | `deployment-*.yaml`   |
| Elasticsearch clusterName  | elasticsearch           | `configmap-*.yaml`    |
| Elasticsearch host         | elasticsearc-master     | `configmap-*.yaml`    |
| Elasticsearch port         | 9200                    | `configmap-*.yaml`    |
| Elasticsearch index prefix | zeebe-record            | `configmap-*.yaml`    |
| Many urls related to Auth  | See `deployment-*.yaml` | `deployment-*.yaml`   |

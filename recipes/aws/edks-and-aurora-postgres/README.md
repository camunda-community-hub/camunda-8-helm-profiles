# Provision AWS EKS with Aurora Postgres 

## Prerequisites

- An AWS account with permissions to create EKS clusters and Aurora databases.
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.
- [eksctl](https://eksctl.io/) installed.
- [psql](https://www.postgresql.org/download/) installed (to create databases).

## Install

This will provision the following: 
- An EKS cluster 
- An Aurora Postgres database cluster and instance
- Allow network traffic from the EKS cluster to the Aurora database
- Allow network traffic from your local machine to the Aurora database (for psql access)
- Create Identity, Modeler, and Keycloak databases and corresponding database users inside Postgres

```sh
make
```

## Uninstall
```sh
make clean
```

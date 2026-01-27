# Provision AWS EKS with Aurora Postgres 
This will provision the following:
- An EKS cluster
- An Aurora Postgres database cluster and instance
- Allow network traffic from the EKS cluster to the Aurora database
- Allow network traffic from your local machine to the Aurora database (for psql access)
- Create Identity, Modeler, and Keycloak databases and corresponding database users inside Postgres

## Prerequisites
- An AWS account with permissions to create EKS clusters and Aurora databases.
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.
- [eksctl](https://eksctl.io/) installed.
- [psql](https://www.postgresql.org/download/) installed (to create databases).

## Install
```sh
make
```

## Uninstall
```sh
make clean
```

## Troubleshooting

### Unable to connect to Aurora Postgres from local machine

This should no longer be an issue because I've updated the `create-db-subnet-group` target to create a subnet group that
includes only public subnets.

Previously, the subnet db group was created using the existing VPC subnets provisioned by the EKS cluster. It seemed that sometimes, the aurora writer instance is in a private subnet, you will not be able to connect to it from your local machine. 

```sh
make check-public-access
```
If any of the subnets are private, use the following to open a route from your local machine to the private subnets: 

```sh
make allow-local-to-subnets
```
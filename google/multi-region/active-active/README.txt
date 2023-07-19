# Multi-Region Active-Active Setup for Camunda 8

## Special Case: Dual-Region Active-Active

### Initial Setup

#### Region 0

Edit [region0/Makefile](region0/Makefile) and adjust `project`, `region`, and `clusterName`.
We recommend to include `region-0` into the `clusterName`
to abstract away from physical region names like `europe-west1-b`.

Edit [region0/camunda-values.yaml](region0/camunda-values.yaml)

```
make kube
make
```

#### Verification
You can check the status of the Zeebe cluster using:
```sh
make zbctl-status
```
The output should look something like this (Note how brokers alternate between two regions `europe-west4-b` and `europe-west1-b` ):
```
Cluster size: 8
Partitions count: 8
Replication factor: 4
Gateway version: 8.2.8
Brokers:
  Broker 0 - camunda-zeebe-0.camunda-zeebe.europe-west4-b.svc:26501
    Version: 8.2.8
    Partition 1 : Leader, Healthy
    Partition 6 : Leader, Healthy
    Partition 7 : Leader, Healthy
    Partition 8 : Leader, Healthy
  Broker 1 - camunda-zeebe-0.camunda-zeebe.europe-west1-b.svc:26501
    Version: 8.2.8
    Partition 1 : Follower, Healthy
    Partition 2 : Follower, Healthy
    Partition 7 : Follower, Healthy
    Partition 8 : Follower, Healthy
  Broker 2 - camunda-zeebe-1.camunda-zeebe.europe-west4-b.svc:26501
    Version: 8.2.8
    Partition 1 : Follower, Healthy
    Partition 2 : Leader, Healthy
    Partition 3 : Leader, Healthy
    Partition 8 : Follower, Healthy
  Broker 3 - camunda-zeebe-1.camunda-zeebe.europe-west1-b.svc:26501
    Version: 8.2.8
    Partition 1 : Follower, Healthy
    Partition 2 : Follower, Healthy
    Partition 3 : Follower, Healthy
    Partition 4 : Follower, Healthy
  Broker 4 - camunda-zeebe-2.camunda-zeebe.europe-west4-b.svc:26501
    Version: 8.2.8
    Partition 2 : Follower, Healthy
    Partition 3 : Follower, Healthy
    Partition 4 : Leader, Healthy
    Partition 5 : Leader, Healthy
  Broker 5 - camunda-zeebe-1.camunda-zeebe.europe-west1-b.svc:26501
    Version: 8.2.8
    Partition 3 : Follower, Healthy
    Partition 4 : Follower, Healthy
    Partition 5 : Follower, Healthy
    Partition 6 : Follower, Healthy
  Broker 6 - camunda-zeebe-3.camunda-zeebe.europe-west4-b.svc:26501
    Version: 8.2.8
    Partition 4 : Follower, Healthy
    Partition 5 : Follower, Healthy
    Partition 6 : Follower, Healthy
    Partition 7 : Follower, Healthy
  Broker 7 - camunda-zeebe-3.camunda-zeebe.europe-west1-b.svc:26501
    Version: 8.2.8
    Partition 5 : Follower, Healthy
    Partition 6 : Follower, Healthy
    Partition 7 : Follower, Healthy
    Partition 8 : Follower, Healthy
```

You can check the status of the Elasticsearch cluster using:
```sh
make elastic-nodes
```

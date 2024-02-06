# Multi-Region Active-Active Setup for Camunda 8

## Prerequisite: Kubernetes Cross-Cluster Communication

A multi-region setup in Kubernetes really means a multi-cluster setup and that comes with a networking challenge:

## Special Case: Dual-Region Active-Active

### Initial Setup

Clone this repository.

#### Prepare Kubernetes Clusters
NOTE: this needs to be done in both regions

The installation configurations are available at the beginning of the makefiles. You may want to change the defaults edit [region0/Makefile](region0/Makefile) and [region1/Makefile](region1/Makefile)
and adjust `region`, `peerRegion`, `cidrBlock`, `publicAccess`, `clusterName` and `peerClusterName`.
These properties will configure the cluster for each region.
The physical region name will be used as a Kubernetes namespace.

The following command will generate the cluster.yaml for the region, create the cluster, apply the storage class, install the CSI addon, install the CNI addon, configure the OIDC provider

```sh
cd region0
make kube

cd ../region1
make kube
cd ..
```

#### Create and accept peering connection
NOTE: this only needs to be done in one region

The following command will create peering connection. The peering connection will be applied to both VPC's

Do this only in region 0

```sh
cd region0

make peering-connection
```

#### Configure IP routing, Update Firewall Rules, Configure CoreDNS
NOTE: this needs to be done in both regions

The following command will add routes to the peering connection in both VPC's, update all inbound and outbound security group rules, replace coredns configmap in the cluster

```sh
cd region0
make networking-rules

cd ../region1
make networking-rules
````

#### Installing Camunda
NOTE: this needs to be done in both regions

IMPORTANT: Before you run the install. See the preconfigured values files [region0/camunda-values.yaml](region0/camunda-values.yaml) and [region1/camunda-values.yaml](region1/camunda-values.yaml) adjust the default properties as needed for your cluster, if you've changed regions or zones [us-west-2, us-east-2] or if you've added zeebe nodes to the cluster.

```
- name: ZEEBE_BROKER_CLUSTER_INITIALCONTACTPOINTS
  value: "camunda-zeebe-0.camunda-zeebe.us-west-2.svc.cluster.local:26502, camunda-zeebe-1.camunda-zeebe.us-west-2.svc.cluster.local:26502, camunda-zeebe-0.camunda-zeebe.us-east-2.svc.cluster.local:26502, camunda-zeebe-1.camunda-zeebe.us-east-2.svc.cluster.local:26502"

- name: ZEEBE_BROKER_EXPORTERS_ELASTICSEARCH2_ARGS_URL
  value: "http://camunda-elasticsearch.us-west-2.svc.cluster.local:9200"

- name: ZEEBE_GATEWAY_CLUSTER_INITIALCONTACTPOINTS
  value: "camunda-zeebe-0.camunda-zeebe.us-west-2.svc.cluster.local:26502, camunda-zeebe-1.camunda-zeebe.us-west-2.svc.cluster.local:26502, camunda-zeebe-0.camunda-zeebe.us-east-2.svc.cluster.local:26502, camunda-zeebe-1.camunda-zeebe.us-east-2.svc.cluster.local:26502"

```
Run the install command

```sh
cd region0
make

cd ../region1
make
```

#### Verification

##### Zeebe

You can check the status of the Zeebe cluster using:

```sh
make port-zeebe
```
In separate terminal run
```sh
zbctl --address localhost:26500 --insecure status
```

The output should look something like this
(Note how brokers alternate between two Kubernetes namespaces
`europe-west4-b` and `us-east1-b` that represent the physical regions,
in which they are hosted.):

```sh
Cluster size: 4
Partitions count: 4
Replication factor: 4
Gateway version: 8.2.8
Brokers:
  Broker 0 - camunda-zeebe-0.camunda-zeebe.europe-west4-b.svc:26501
    Version: 8.2.8
    Partition 1 : Leader, Healthy
    Partition 6 : Leader, Healthy
    Partition 7 : Leader, Healthy
    Partition 8 : Leader, Healthy
  Broker 1 - camunda-zeebe-0.camunda-zeebe.us-east1-b.svc:26501
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
  Broker 3 - camunda-zeebe-1.camunda-zeebe.us-east1-b.svc:26501
    Version: 8.2.8
    Partition 1 : Follower, Healthy
    Partition 2 : Follower, Healthy
    Partition 3 : Follower, Healthy
    Partition 4 : Follower, Healthy
```

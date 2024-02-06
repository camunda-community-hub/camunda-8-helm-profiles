# Multi-Region Active-Active Setup for Camunda 8

Note: This Helm profile uses a [slightly-modified version of Camunda's Helm chart](https://github.com/camunda-consulting/camunda-platform-helm-multi-region/tree/main) (a [pull request](https://github.com/camunda/camunda-platform-helm/pull/1006) is pending).

## Prerequisite: Kubernetes Cross-Cluster Communication

A multi-region setup in Kubernetes really means a multi-cluster setup and that comes with a networking challenge: How to manage connectivity between my pods across different Kubernetes clusters? You should setup proper firewall rules and correctly route traffic among the pods. For that you have many options:
* ["DNS Chainging" with kube-dns](https://youtu.be/az4BvMfYnLY?si=RmauCqchHwsmCDZZ&t=2004): That's the option we took in this example. We setup kube-dns automatically through a [python script](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/main/google/multi-region/active-active/setup-zeebe.py) to route traffic to the distant cluster based on the namespace. This requires to have different namespaces in each cluster.
* [Istio](https://medium.com/@danielepolencic/scaling-kubernetes-to-multiple-clusters-and-regionss-491813c3c8cd) ([video](https://youtu.be/_8FNsvoECPU?si=dUOFwaaUxRroj8MP))
* [Skupper](https://medium.com/@shailendra14k/deploy-the-skupper-networks-89800323925c#:~:text=Skupper%20creates%20a%20service%20network,secure%20communication%20across%20Kubernetes%20clusters.)
* [Linkerd multi-cluster communication](https://linkerd.io/2.14/features/multicluster/)
* [Google Kubernetes Engine (GKE) Fleet Management](https://cloud.google.com/kubernetes-engine/docs/fleets-overview)
* [Azure Kubernetes Fleet Manager](https://azure.microsoft.com/en-us/products/kubernetes-fleet-manager)
* etc.

## Special Case: Dual-Region Active-Active



### Initial Setup

### Prepare installation

You should clone this repository as well as the [second one](https://github.com/camunda-consulting/camunda-platform-helm-multi-region/tree/main) locally.
This repository references the first one in the makefile of each region : https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/d9168169ffe368a817e67c8cd70217ace1071285/google/multi-region/active-active/region0/Makefile#L29. So depending on how you clone these repositories you may want to change that line.

The installation configurations are available at the beginning of these makefiles (clustername, region, project, machine type, etc). For this example, we decided to name our namespaces as our regions for an easier readability. You may want to change this. In such a case and if you want to use setup-zeebe.py to configure kube-dns,  this script should be updated accordingly.

#### Prepare Kubernetes Clusters
NOTE: this needs to be done in both regions

Edit [region0/Makefile](region0/Makefile) and [region1/Makefile](region1/Makefile)
and adjust `region`, `peerRegion`, `cidrBlock`, `publicAccess`, `clusterName` and `peerClusterName`.
These properties will configure the cluster for each region.
The physical region name will be used as a Kubernetes namespace.

```sh
cd region0
make kube
cd ../region1
make kube
cd ..
```

#### Create and accept peering connection
NOTE: this only needs to be done in one region

Create peering connection
Do this only in region 0

```sh
make peering-connection
```

#### Configure IP routing, Update Firewall Rules, Configure CoreDNS
NOTE: this needs to be done in both regions
update all inbond and outbound security group rules
replace coredns configmap in the cluster

```sh
make networking-rules
````

#### Installing Camunda
NOTE: this needs to be done in both regions

IMPORTANT: Before you run the install. See the preconfigured values files [region0/camunda-values.yaml](region0/camunda-values.yaml) and [region1/camunda-values.yaml](region1/camunda-values.yaml) adjust the following properties as needed for your cluster.

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
Inseperate terminal run
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

##### Operate

Operate has a defect for now and if the zeebe brokers negotiation takes too long, Operate will look "healthy" but will not start the importer. You may need to delete the operate pod to force its recreation once the zeebe cluster is healthy.


##### Elasticsearch

Elastic doesn't support a dual active active setup. You would need a tie breaker in a 3rd region : https://www.elastic.co/guide/en/elasticsearch/reference/current/high-availability-cluster-design-large-clusters.html#high-availability-cluster-design-two-zones
Cross Cluster Replication is an Active-Passive setup that doesn't fit the current requirement.

So the current approach would be to have 2 ES clusters in each region with their own Operate,Tasklist, Optimize on top of it. In case of disaster (loosing a region), procedure would be to pause the exporters & then start the failOver.
Once the failback is started, resume the exporters.

You can check the status of the Elasticsearch cluster using:

```sh
make elastic-nodes
```

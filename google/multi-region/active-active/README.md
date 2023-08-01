# Multi-Region Active-Active Setup for Camunda 8

Note: This Helm profile uses a [slightly-modified version of Camunda's Helm chart](https://github.com/camunda/camunda-platform-helm/pull/806).

## Special Case: Dual-Region Active-Active

We are basing our dual-region active-active setup on standard Kubernetes features that are cloud-provider-independent. The heavy-lifting of the setup is done by kubectl and Helm. Python and Make are just used for scripting combinations of kubectl and Helm. These scripts could be easily ported to Infrastructure as Code languages. You can run `make --dry-run` on any of the Makefile targets mentioned below to see which kubectl and Helm commands are used.

### Initial Setup

#### Kubernetes Clusters

Edit [region0/Makefile](region0/Makefile) and [region1/Makefile](region1/Makefile)
and adjust `project`, `region`, and `clusterName`.
We recommend to include `region-0` into the `clusterName`
to abstract away from physical region names like `europe-west1-b`.
The physical region name will however be used as a Kubernetes namespace.

```sh
cd region0
make kube
cd ../region1
make kube
cd ..
```

Edit the Python script [setup-zeebe.py](./setup-zeebe.py)
and adjust the lists of `contexts` and `regions`.
To get the names of your kubectl "contexts" for each of your clusters, run:

```sh
kubectl config get-contexts
```

Then run that script to adjust the DNS configuration of both Kubernetes clusters
so that they can resolve each others service names.

```sh
./setup-zeebe.py
```

#### Enabling Firewall rules
To allow communication between the zeebe nodes and from the zeebe nodes to the Elasticsearch, we need to authorize the traffic.
The rule should have the correct :
- Target tags : can be retrieved from VM Instance => Network tags
- IP ranges : can be retrieved from cluster detailed => Cluster Pod IPv4 range (default)
- Protocols and ports : tcp:26502 and tcp:9200

#### Installing Camunda

Edit [region0/camunda-values.yaml](region0/camunda-values.yaml) and adjust
`ZEEBE_BROKER_CLUSTER_INITIALCONTACTPOINTS`

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
make zbctl-status
```

The output should look something like this
(Note how brokers alternate between two Kubernetes namespaces
`europe-west4-b` and `europe-west1-b` that represent the physical regions,
in which they are hosted.):

```sh
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


##### Operate

Operate has a defect for now and if the zeebe brokers negociation takes too long, Operate will look "healthy" but will not start the importer. You may need to delete the operate pod to force its recreation once the zeebe cluster is healthy.


##### Elasticsearch

Elastic doesn't support a dual active active setup. You would need a tie breaker in a 3rd region : https://www.elastic.co/guide/en/elasticsearch/reference/current/high-availability-cluster-design-large-clusters.html#high-availability-cluster-design-two-zones
Cross Cluster Replication is an Active-Passive setup that doesn't fit the current requirement.

So the current approach would be to have 2 ES clusters in each region with their own Operate,Tasklist, Optimize on top of it. In case of disaster (loosing a region), procedure would be to pause the exporters. Start the failOver.
Once the failback is started, resume the exporters.

You can check the status of the Elasticsearch cluster using:

```sh
make elastic-nodes
```

### Disaster

In case of disaster, loosing a region, attempting to start a process instance would lead to an exception :

io.grpc.StatusRuntimeException: RESOURCE_EXHAUSTED: Expected to execute the command on one of the partitions, but all failed; there are no more partitions available to retry. Please try again. If the error persists contact your zeebe operator

the procedure would be to :
* start temporary nodes that will restore the quorum in the surviving region
* restore disaster region
	* take snapshots in the surviving region
    * restore missing nodes in the disastered region (wihtout operate and tasklist)
	* pause exporters
	* restore snapshots in the disastered region
	* resume exporters
* clean the temporary nodes from the surviving region
* restore the initial setup

##### pause exporters

TODO: write a makefile target to pause exporters in the surviving region


##### start temporary nodes (failOver)

In the surviving region, use the "make fail-over-regionX" to create the temporary nodes with the partitions to restore the qorum.
If region0 survived, the command would be

```sh
cd region0
make fail-over-region1
```

If region1 survived, the command would be

```sh
cd region1
make fail-over-region0
```

##### restore missing nodes in the disastered region (failBack)

Once you're able to restore the disaster region, you don't want to restart all nodes. Else you will end-up with some brokerIds duplicated (from the failOver). So instead, you want to restart only missing brokerIds.
```sh
cd region0
make fail-back
```

> :information_source: This will indeed create all the brokers. But half of them (the ones in the failOver) will not be started (start script is altered in the configmap)

##### resume exporters

You now have 2 active regions again and you may want to resume the exporters. 
TODO: write a makefile target to resume exporters in the surviving region
TODO : before resuming, it would be required to snapshot the surviving Elastic and restore it in the disastered region. Describe the procedure

##### clean the temporary nodes (prepare transition to initial state)

You can safely delete the temporary nodes from surviving region as the quorum is garantied by the restored brokers in the disastered region.

```sh
cd region0
make clean-fail-over-region1
```

##### restore the initial setup (back to normal)

You now want to recreate the missing brokers in the disastered region.

```sh
cd region1
make fail-back-to-normal
```

> :information_source: This will change the startup script in the configmap and delete the considered pods (to force recreation). The pod deletion should be changed depending on your initial setup.

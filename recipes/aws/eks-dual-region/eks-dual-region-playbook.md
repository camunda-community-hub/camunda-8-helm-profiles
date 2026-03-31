# Camunda 8.9 Dual-Region Operations Playbook

## Overview

This playbook covers the operational procedures for a Camunda 8.9 dual-region deployment on AWS EKS using the `orchestration-internal-postgres` recipe. It is based on the [official Camunda dual-region documentation](https://docs.camunda.io/docs/next/self-managed/concepts/multi-region/dual-region/) and lessons learned from testing with this recipe.

**Architecture:** Hybrid active-active/active-passive across two AWS regions with VPC peering and DNS chaining. PostgreSQL (RDBMS) is used as secondary storage — no Elasticsearch required.

**Recipe:** `recipes/camunda/8.9/orchestration-internal-postgres`
**Infrastructure:** `recipes/aws/eks-dual-region`

---

## Cluster Topology

| Property | Value |
|---|---|
| **clusterSize** | 4 (total across both regions) |
| **Brokers per region** | 2 (chart divides clusterSize by regions) |
| **replicationFactor** | 4 |
| **partitionCount** | 4 |
| **Node ID formula** | `podIndex * regions + regionId` |

**Broker distribution:**

| Pod | Region | Node ID | Partitions |
|---|---|---|---|
| `camunda-zeebe-0` | Region 0 | 0 | 1, 2, 3, 4 |
| `camunda-zeebe-1` | Region 0 | 2 | 1, 2, 3, 4 |
| `camunda-zeebe-0` | Region 1 | 1 | 1, 2, 3, 4 |
| `camunda-zeebe-1` | Region 1 | 3 | 1, 2, 3, 4 |

Zeebe distributes partition leadership in a round-robin fashion. With `replicationFactor: 4`, every partition is replicated to all 4 brokers. Quorum requires 3 of 4 brokers — losing an entire region (2 brokers) means quorum is lost.

---

## Day-to-Day Operations

### Check Cluster Health

```bash
# Switch context and port-forward
make use-region0
make port-orchestration-region0

# In another terminal:
make topology CLUSTER_0=<your-cluster-0>
```

**Healthy topology indicators:**
- All 4 brokers visible (nodeId 0, 1, 2, 3)
- Each partition has exactly one `leader` and three `follower` roles
- All partitions report `health: "healthy"`

### Deploy and Test BPMN

```bash
# With port-forwarding active:
make test-bpmn                    # Deploy + create instance + get tasks
make deploy-bpmn BPMN_FILE=hello_user_task.bpmn
make create-instance PROCESS_ID=Process_08p1wio
make get-tasks
make get-definitions
make get-instances
```

### View Pods in Each Region

```bash
make pods-region0
make pods-region1
```

---

## Failure Scenarios

### Scenario 1: Network Partition (VPC Route Loss)

**Cause:** Network connectivity between regions is lost (e.g., VPC peering route deleted, network outage).

**Symptoms:**
- Broker logs: `Failed to resolve DNS` or `Member unreachable` for cross-region brokers
- Topology shows only local brokers (2 instead of 4)
- All partitions become `follower` — no leaders elected (quorum lost)
- API calls fail: `"Expected to handle request, but there was a connection error with one of the brokers"`

**Simulate:**

```bash
make simulate-partition \
  CLUSTER_0=<cluster-0> CLUSTER_1=<cluster-1> \
  AWS_REGION_0=<region-0> AWS_REGION_1=<region-1>
```

**Impact:**
- Processing **stops immediately** — no new instances, no task completion
- Existing data is safe (Raft log is durable on each broker)
- RDBMS exporter stalls — search APIs return stale data
- Both regions' pods remain running

**Restore:**

```bash
make restore-partition \
  CLUSTER_0=<cluster-0> CLUSTER_1=<cluster-1> \
  AWS_REGION_0=<region-0> AWS_REGION_1=<region-1>
```

**Recovery behavior:**
- Zeebe automatically detects restored connectivity (SWIM protocol probes every 2s)
- Raft re-establishes quorum and elects leaders (30-60 seconds)
- RDBMS exporter catches up on backlog
- No manual intervention required beyond restoring network

**Verify recovery:**

```bash
# Wait 60 seconds, then:
make topology CLUSTER_0=<cluster-0>
make test-bpmn
```

---

### Scenario 2: Region Broker Crash

**Cause:** Broker pods in one region crash or are evicted.

**Symptoms:** Same as network partition — quorum lost, processing stops.

**Recover:**

```bash
# If pods are in CrashLoopBackOff, delete them to force restart:
kubectl --context <cluster-1> -n <namespace-1> delete pods -l app.kubernetes.io/component=zeebe-broker

# Watch recovery:
kubectl --context <cluster-1> -n <namespace-1> get pods -w
```

Brokers will restart with existing PVC data and rejoin the Raft cluster.

---

### Scenario 3: Full Region Loss

**Cause:** Entire region is unavailable (AWS outage, cluster deleted).

**Impact:**
- Zeebe quorum lost — processing stops
- Primary region loss: user traffic unavailable
- Secondary region loss: user traffic unaffected but processing stops

**Recovery — Failover (Temporary):**

Follow the [official Camunda failover procedure](https://docs.camunda.io/docs/next/self-managed/deployment/helm/operational-tasks/dual-region-operational-procedure/):

1. Scale surviving region to handle solo operation (failover mode)
2. Redirect user traffic to surviving region if primary was lost
3. Processing resumes in degraded mode

**Recovery — Failback (Permanent):**

1. Restore or recreate the failed region's EKS cluster
2. Redeploy Camunda brokers in failback mode
3. Wait for data replication to complete
4. Resume normal dual-region operation
5. Remove failover configuration

> **Important:** The failover/failback procedures are complex and should be tested in non-production environments before relying on them. Refer to the official docs for detailed steps.

---

### Scenario 4: Authorization Distribution Failure

**Cause:** User authorizations (e.g., `demo/demo`) fail to replicate across partitions after a partition event.

**Symptoms:**
- One region returns `401 Unauthorized` on API calls
- Logs show: `Not sending command AUTHORIZATION CREATE to <partition>, no known leader`
- `CommandRedistributor` retrying authorization distribution

**Recover:**

```bash
# Restart brokers in the affected region to force redistribution:
kubectl --context <cluster> -n <namespace> delete pods -l app.kubernetes.io/component=zeebe-broker
```

Wait 60 seconds for pods to restart and authorizations to propagate, then retry API calls.

---

### Scenario 5: RDBMS Exporter Stall

**Cause:** Exporter falls behind after partition recovery or PostgreSQL issues.

**Symptoms:**
- `get-instances` returns stale data (missing recently created instances)
- Direct lookup by key returns 404
- Logs show: `Partition-N failed, marking it as unhealthy` then `Partition-N recovered, marking it as healthy`

**Recover:**

Typically self-resolves as the exporter catches up. If stalled for more than 5 minutes:

```bash
# Check exporter status:
kubectl --context <cluster> -n <namespace> logs <zeebe-pod> | grep -i "export\|rdbms"

# If necessary, restart the statefulset:
kubectl --context <cluster> -n <namespace> rollout restart statefulset camunda-zeebe
```

---

## Recovery Time Expectations

| Scenario | RPO | RTO |
|---|---|---|
| Network partition (restored) | 0 | 30-60 seconds after connectivity restored |
| Broker pod restart | 0 | 1-3 minutes |
| Full region failover | 0 | < 1 minute (excluding DNS reconfiguration) |
| Full region failback | 0 | 5+ minutes (depends on data volume) |
| RDBMS exporter catch-up | 0 | 1-5 minutes after partition recovery |

---

## Key Make Targets Reference

### Infrastructure (from `recipes/aws/eks-dual-region/`)

| Target | Description |
|---|---|
| `create-cluster-region0/1` | Create EKS cluster |
| `configure-vpc-peering` | Full VPC peering setup |
| `configure-dns` | DNS chaining between clusters |
| `test-dns` | Verify cross-region DNS |
| `simulate-partition` | Remove VPC routes (simulate outage) |
| `restore-partition` | Re-add VPC routes (restore connectivity) |

### Camunda (from `recipes/camunda/8.9/orchestration-internal-postgres/`)

| Target | Description |
|---|---|
| `deploy-dual-region` | Deploy Camunda to both regions |
| `clean-dual-region` | Uninstall from both regions |
| `topology` | Check Zeebe cluster topology |
| `port-orchestration-region0/1` | Port-forward REST API |
| `use-region0/1` | Switch kubectl context |
| `test-bpmn` | Deploy BPMN + create instance + get tasks |
| `pods-region0/1` | List pods per region |

---

## Network Requirements

| Port | Protocol | Purpose |
|---|---|---|
| 26500 | TCP | Zeebe Gateway (client/worker communication) |
| 26501 | TCP | Zeebe internal (broker ↔ gateway) |
| 26502 | TCP | Zeebe internal (broker ↔ broker) |
| 5432 | TCP | PostgreSQL |
| 8080 | TCP | REST API |
| 53 | TCP/UDP | DNS (CoreDNS cross-cluster forwarding) |

Maximum network RTT between regions: **100ms**.

---

## Limitations

- **Identity:** Management Identity (multi-tenancy, RBAC) not available in dual-region. Cluster-level Identity via Orchestration is supported.
- **Optimize:** Not supported in dual-region.
- **Connectors:** Can be deployed but idempotency must be managed to avoid event duplication.
- **Web Modeler:** Not covered; has dependency on Management Identity.
- **OpenSearch:** Not supported in dual-region configurations.
- **Upgrades:** Use staged approach — upgrade one region at a time. Never upgrade both simultaneously.

---

## Further Reading

- [Dual-region concept](https://docs.camunda.io/docs/next/self-managed/concepts/multi-region/dual-region/)
- [AWS EKS dual-region setup](https://docs.camunda.io/docs/next/self-managed/deployment/helm/cloud-providers/amazon/amazon-eks/dual-region/)
- [Failover/failback operational procedure](https://docs.camunda.io/docs/next/self-managed/deployment/helm/operational-tasks/dual-region-operational-procedure/)
- [Camunda c8-multi-region test repo](https://github.com/camunda/c8-multi-region)
- [camunda-8-helm-profiles (dave-2026 branch)](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/dave-2026/)
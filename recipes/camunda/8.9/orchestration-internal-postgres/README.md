# Camunda 8.9 — Orchestration with Internal PostgreSQL

This recipe deploys Camunda 8.9 using the unified Orchestration Cluster (Zeebe + Operate + Tasklist + Identity) with an internal PostgreSQL database as secondary storage. No Elasticsearch required.

Supports both **single-region** and **dual-region** deployments.

## Prerequisites

- A running Kubernetes cluster (see `recipes/aws/eks/` for single-region or `recipes/aws/eks-dual-region/` for dual-region)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed and configured
- [Helm](https://helm.sh/docs/intro/install/) >= 3.9.x
- [jq](https://jqlang.github.io/jq/download/) installed (for testing targets)
- GNU `make` installed

## Quick Start — Single-Region

```bash
cd recipes/camunda/8.9/orchestration-internal-postgres/

# Deploy
make

# Verify
make port-orchestration
# In another terminal:
make test-bpmn

# Cleanup
make clean
```

## Quick Start — Dual-Region on AWS

### Step 1: Provision Infrastructure

```bash
cd recipes/aws/eks-dual-region/

# Create both clusters (run in parallel in separate terminals)
make create-cluster-region0
make create-cluster-region1

# Configure networking
make configure-vpc-peering
make configure-dns
make test-dns
```

### Step 2: Deploy Camunda

```bash
cd recipes/camunda/8.9/orchestration-internal-postgres/

# Deploy to both regions
make deploy-dual-region CLUSTER_0=<cluster-0> CLUSTER_1=<cluster-1>
```

### Step 3: Verify

```bash
# Check topology — should show 4 brokers across 2 regions
make topology CLUSTER_0=<cluster-0>

# Port-forward and test
make port-orchestration-region0
# In another terminal:
make test-bpmn
```

### Cleanup

```bash
# Remove Camunda from both regions
make clean-dual-region CLUSTER_0=<cluster-0> CLUSTER_1=<cluster-1>

# Remove infrastructure
cd ../../aws/eks-dual-region/
make clean
```

## Configuration

Override defaults by creating a `config.mk` in the project root or editing `./config.mk`.

### Key Variables

| Variable | Default | Description |
|---|---|---|
| `CAMUNDA_NAMESPACE` | `camunda` | Namespace for single-region deployment |
| `CAMUNDA_RELEASE_NAME` | `camunda` | Helm release name |
| `CAMUNDA_CLUSTER_SIZE` | `1` | Zeebe cluster size (single-region) |
| `DEFAULT_PASSWORD` | `demo` | Default password for all credentials |

### Dual-Region Variables

| Variable | Default | Description |
|---|---|---|
| `CLUSTER_0` | *(required)* | kubectl context for region 0 |
| `CLUSTER_1` | *(required)* | kubectl context for region 1 |
| `CAMUNDA_NAMESPACE_0` | `camunda-region0` | Namespace in region 0 |
| `CAMUNDA_NAMESPACE_1` | `camunda-region1` | Namespace in region 1 |
| `CAMUNDA_CLUSTER_SIZE_DR` | `4` | Total brokers across both regions |
| `CAMUNDA_REPLICATION_FACTOR_DR` | `4` | Must equal cluster size |
| `CAMUNDA_PARTITION_COUNT_DR` | `4` | Number of partitions |
| `AWS_REGION_0` | `us-east-1` | AWS region for cluster 0 |
| `AWS_REGION_1` | `us-west-2` | AWS region for cluster 1 |

## Dual-Region Architecture

The dual-region deployment uses a hybrid active-active/active-passive architecture:

- **Zeebe**: Active-active — brokers in both regions participate in Raft consensus
- **Operate/Tasklist**: Active-passive for user traffic, active-active for data
- **Identity**: Embedded, active-active
- **PostgreSQL**: Independent instance per region, populated by RDBMS exporter

The chart sets `orchestration.clusterSize: 4` with `global.multiregion.regions: 2`, which creates 2 pods per region. Node IDs are computed as `podIndex * regions + regionId`, giving unique IDs 0, 2 in region 0 and 1, 3 in region 1.

### Network Requirements

Ports that must be open between regions:

| Port | Protocol | Purpose |
|---|---|---|
| 26500 | TCP | Zeebe Gateway |
| 26501-26502 | TCP | Zeebe broker-to-broker |
| 5432 | TCP | PostgreSQL |
| 8080 | TCP | REST API |
| 53 | TCP/UDP | DNS forwarding |

Maximum RTT between regions: **100ms**.

### Limitations

- Identity (multi-tenancy/RBAC): not available
- Optimize: not supported
- Connectors: can be deployed but requires idempotency management
- Web Modeler: not covered
- OpenSearch: not supported

## Make Targets

Run `make help` for the full list. Key targets:

### Single-Region

| Target | Description |
|---|---|
| `all` | Deploy Camunda (generate values + credentials + install) |
| `clean` | Uninstall Camunda |
| `port-orchestration` | Port-forward REST API (8080) |
| `port-zeebe` | Port-forward gRPC (26500) |

### Dual-Region

| Target | Description |
|---|---|
| `deploy-dual-region` | Deploy to both regions |
| `deploy-region0` | Deploy to region 0 only |
| `deploy-region1` | Deploy to region 1 only |
| `clean-dual-region` | Uninstall from both regions |
| `use-region0` / `use-region1` | Switch kubectl context |
| `port-orchestration-region0` / `region1` | Port-forward per region |
| `topology` | Check Zeebe cluster topology |
| `pods-region0` / `pods-region1` | List pods per region |

### Testing

| Target | Description |
|---|---|
| `test-bpmn` | Deploy BPMN + create instance + get tasks |
| `deploy-bpmn` | Deploy a BPMN model (default: `hello_user_task.bpmn`) |
| `create-instance` | Create a process instance |
| `get-tasks` | Search for user tasks |
| `get-definitions` | List process definitions |
| `get-instances` | List process instances |

### Failure Simulation (requires `AWS_REGION_0`/`AWS_REGION_1`)

| Target | Description |
|---|---|
| `simulate-partition` | Remove VPC routes to simulate network outage |
| `restore-partition` | Re-add VPC routes to restore connectivity |

## Files

| File | Purpose |
|---|---|
| `Makefile` | Recipe entry point — includes shared makefiles |
| `config.mk` | Default configuration variables |
| `my-camunda-values.yaml` | Recipe-specific Helm values overrides |
| `DUAL-REGION-PLAYBOOK.md` | Operational playbook for failure scenarios |

### Shared Makefiles (in `makefiles/`)

| File | Purpose |
|---|---|
| `camunda.mk` | Core Camunda Helm install/uninstall/port-forward |
| `camunda-dual-region.mk` | Dual-region deploy, context switching, topology, failure simulation |
| `camunda-test.mk` | BPMN deploy and REST API test targets |
| `aws-eks.mk` | EKS cluster creation (single-region) |
| `aws-eks-dual-region.mk` | VPC peering, DNS chaining, dual-cluster management |

### Helm Values (in `camunda-values.yaml.d/8.9/`)

| File | Purpose |
|---|---|
| `disable-all.yaml` | Disables all components (base for composing) |
| `enable-identity-postgres.yaml` | Enables Identity PostgreSQL |
| `orchestration-rdbms-postgres.yaml` | Configures RDBMS as secondary storage |
| `dual-region.yaml` | Dual-region overlay (multiregion, cluster sizing, env vars) |

## Further Reading

- [Camunda dual-region concept](https://docs.camunda.io/docs/next/self-managed/concepts/multi-region/dual-region/)
- [AWS EKS dual-region setup](https://docs.camunda.io/docs/next/self-managed/deployment/helm/cloud-providers/amazon/amazon-eks/dual-region/)
- [Failover/failback procedure](https://docs.camunda.io/docs/next/self-managed/deployment/helm/operational-tasks/dual-region-operational-procedure/)
- [DUAL-REGION-PLAYBOOK.md](./DUAL-REGION-PLAYBOOK.md) — Operational playbook for this recipe
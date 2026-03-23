# Camunda 8.9 Dual-Region on AWS EKS (PostgreSQL / No Elasticsearch)

Deploy Camunda 8.9 in a dual-region active-active configuration across two AWS EKS clusters, using PostgreSQL (RDBMS) as the secondary storage backend instead of Elasticsearch.

## Architecture

```
┌─────────────────────────────┐     VPC Peering      ┌─────────────────────────────┐
│  Region 0 (e.g., us-east-1) │ ◄──────────────────► │  Region 1 (e.g., ca-central-1)│
│                             │   CoreDNS chaining   │                              │
│  EKS Cluster 0              │                      │  EKS Cluster 1               │
│  ┌────────────────────────┐ │                      │  ┌────────────────────────┐  │
│  │ Namespace: camunda-r0  │ │                      │  │ Namespace: camunda-r1  │  │
│  │                        │ │                      │  │                        │  │
│  │  Zeebe Broker 0 (even) │ │                      │  │  Zeebe Broker 1 (odd)  │  │
│  │  Zeebe Broker 2 (even) │ │                      │  │  Zeebe Broker 3 (odd)  │  │
│  │  Zeebe Gateway         │ │                      │  │  Zeebe Gateway         │  │
│  │  PostgreSQL            │ │                      │  │  PostgreSQL            │  │
│  │  Operate               │ │                      │  │  Operate               │  │
│  │  Tasklist              │ │                      │  │  Tasklist              │  │
│  └────────────────────────┘ │                      │  └────────────────────────┘  │
└─────────────────────────────┘                      └─────────────────────────────┘
```

**Key 8.9 features leveraged:**
- RDBMS (PostgreSQL) as secondary storage — no Elasticsearch dependency
- Active-active is the default for dual-region (Tasklist V2 + v2 REST API)
- New standardized secret management pattern

## Prerequisites

- Two AWS accounts/regions with permissions to create EKS clusters
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [eksctl](https://eksctl.io/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Helm](https://helm.sh/docs/intro/install/) >= 3.19
- [yq](https://github.com/mikefarah/yq) installed (for values composition)
- [jq](https://stedolan.github.io/jq/) installed (for verification)
- GNU `make`

## Quick Start

### 1. Configure your environment

Edit `config.mk` to set your regions, cluster names, and namespaces:

```makefile
AWS_REGION_0 ?= us-east-1
AWS_REGION_1 ?= ca-central-1
CLUSTER_0 ?= myDualRegion-region0
CLUSTER_1 ?= myDualRegion-region1
CAMUNDA_NAMESPACE_0 ?= camunda-region0
CAMUNDA_NAMESPACE_1 ?= camunda-region1
```

> ⚠️ **Critical**: Namespaces MUST be different between clusters. CoreDNS cannot distinguish traffic if both clusters use the same namespace.

### 2. Create EKS clusters

```bash
make create-clusters
```

This creates two EKS clusters and configures your kubeconfig with aliases.

### 3. Set up VPC peering

Configure VPC peering between the two clusters to enable cross-region pod communication:

```bash
make configure-vpc-peering
```

This target automates the full VPC peering setup:
- Creates a VPC peering connection from Region 0 to Region 1
- Accepts the peering connection in Region 1
- Updates route tables in both VPCs to route traffic through the peering connection
- Configures security groups to allow ports 26500-26502 (Zeebe), 53 (DNS), 5432 (PostgreSQL), and 8080 between VPCs

You can check the peering status with:

```bash
make vpc-peering-status
```

### 4. Configure DNS chaining

```bash
make configure-dns
```
This target automates the full DNS chaining setup:
- Deploys internal DNS load balancers in both clusters
- Waits for NLBs to be provisioned (with 60s initial delay)
- Resolves NLB hostnames to IPs
- Patches CoreDNS in both clusters to forward cross-region namespace queries
- Restarts CoreDNS deployments

If the load balancers aren't ready yet (DNS resolution fails), wait and retry:

```bash
sleep 60 && make apply-coredns-config
```


Verify DNS resolution across regions:

```bash
make test-dns
```

### 5. Deploy Camunda

```bash
# Deploy to both regions
make deploy-region0
make deploy-region1
```

### 6. Verify

```bash
# Check pods in both regions
make pods

# Check Zeebe topology
make verify
# (follow the printed instructions for port-forwarding)
```

The topology should show 4 brokers (2 per region), 4 partitions, replication factor 4.

## Make Targets

| Target | Description |
|---|---|
| `make` | Full setup: clusters + DNS + deploy |
| `make create-clusters` | Create both EKS clusters |
| `make configure-kubeconfig` | Set up kubeconfig aliases |
| `make configure-vpc-peering` | Full VPC peering setup (create, accept, routes, security groups) |
| `make vpc-peering-status` | Show current VPC peering connection status |
| `make clean-vpc-peering` | Delete VPC peering connection |
| `make configure-dns` | Deploy DNS LBs and generate CoreDNS config |
| `make test-dns` | Test cross-region DNS resolution |
| `make deploy` | Deploy Camunda to both regions |
| `make deploy-region0` | Deploy Camunda to region 0 only |
| `make deploy-region1` | Deploy Camunda to region 1 only |
| `make pods` | List pods in both regions |
| `make topology` | Show Zeebe cluster topology |
| `make verify` | Print verification instructions |
| `make clean` | Uninstall Camunda from both regions |
| `make clean-clusters` | Delete both EKS clusters |
| `make clean-generated` | Remove generated values files |

## Customization

1. **`config.mk`** — Change regions, instance types, cluster sizes, chart versions
2. **`my-camunda-values.yaml`** — Add recipe-specific Helm overrides (applied last)
3. **Root `config.mk`** — Override defaults across all recipes

### Scaling the Zeebe cluster

The default is 4 brokers (2 per region). To scale to 8:

```makefile
# In config.mk
CAMUNDA_CLUSTER_SIZE ?= 8
CAMUNDA_PARTITION_COUNT ?= 8
```

`CAMUNDA_REPLICATION_FACTOR` must always be 4 for dual-region.

## Limitations

- **VPC peering**: Not automated — must be configured manually or via Terraform
- **No Elasticsearch**: This recipe uses RDBMS; if you need ES-based features, use a different recipe
- **Identity/Keycloak**: Disabled — uses basic auth (demo/demo)
- **Connectors, Optimize, Web Modeler**: Disabled
- **Not production-ready**: Missing ingress, TLS, proper secret management, monitoring

## Troubleshooting

### Zeebe brokers not forming cluster
- Verify DNS chaining: `make test-dns`
- Check VPC peering route tables
- Verify security groups allow ports 26501, 26502 between VPCs
- Check CoreDNS logs: `kubectl --context $CLUSTER_0 logs -f deployment/coredns -n kube-system`

### PostgreSQL connection errors
- Each region has its own PostgreSQL instance (internal `identityPostgresql`)
- The RDBMS URL points to the local PostgreSQL in each region

### Pods stuck in Pending
- Check node capacity: `kubectl describe nodes`
- Verify EBS CSI driver is installed (required for PVCs on EKS >= 1.23)

## References

- [Camunda Dual-Region Concept](https://docs.camunda.io/docs/next/self-managed/concepts/multi-region/dual-region/)
- [AWS EKS Dual-Region Setup Guide](https://docs.camunda.io/docs/next/self-managed/deployment/helm/cloud-providers/amazon/amazon-eks/dual-region/)
- [Dual-Region Operational Procedure](https://docs.camunda.io/docs/next/self-managed/deployment/helm/operational-tasks/dual-region-operational-procedure/)
- [Camunda Deployment References (Terraform)](https://github.com/camunda/camunda-deployment-references/tree/main/aws/kubernetes/eks-dual-region)
- [RDBMS Secondary Storage](https://docs.camunda.io/docs/next/self-managed/concepts/secondary-storage/configuring-secondary-storage/)

# Multi-Region Camunda 8 Helm Profile - AI Agent Documentation

## Overview

This directory contains Helm profiles for deploying **Camunda 8 in a multi-region active-active configuration**. The primary implementation is a **dual-region stretch cluster** that provides high availability and disaster recovery capabilities by distributing Camunda components across two geographic regions.

## Directory Structure

```
multi-region/
└── dual-region/
    ├── Makefile                           # Root Makefile to orchestrate deployment across all regions
    ├── README.md                          # Human-readable documentation
    ├── export_environment_prerequisites.sh # Environment variable setup script
    ├── generate_zeebe_helm_values.sh      # Script to generate Zeebe cluster contact points
    ├── service-per-broker.yaml            # Kubernetes Service definitions for Zeebe broker discovery
    ├── service-per-broker-template.yaml   # Template for single broker service
    ├── service-per-broker-single-region.yaml # Service definitions for single-region setup
    ├── region0/                           # First primary region configuration
    │   ├── Makefile                       # Region-specific Makefile
    │   ├── config.mk                      # Configuration variables (namespace, chart version)
    │   └── region0.yaml                   # Region-specific Helm values (regionId: 0)
    ├── region1/                           # Second primary region configuration
    │   ├── Makefile
    │   ├── config.mk
    │   └── region1.yaml                   # Region-specific Helm values (regionId: 1)
    └── region2/                           # Tiebreaker region (Elasticsearch voting-only node)
        ├── Makefile
        ├── config.mk
        └── region2.yaml                   # Elasticsearch voting-only master node config
```

## Architecture Concept: 2.5-Region Stretch Cluster

### What is a "2.5-Region" Setup?

This profile implements a **2.5-datacenter stretch cluster** architecture:

1. **Region 0 (Primary)**: Full Camunda deployment with Zeebe brokers and Elasticsearch data/master node
2. **Region 1 (Primary)**: Full Camunda deployment with Zeebe brokers and Elasticsearch data/master node
3. **Region 2 (Tiebreaker)**: Elasticsearch voting-only master node ONLY (no Camunda components)

The "2.5" refers to the fact that Region 2 only contains a minimal Elasticsearch component for quorum purposes.

### Why This Architecture?

- **Zeebe**: Uses Raft consensus protocol requiring quorum. With 4 brokers (2 per region) and replicationFactor=4, all partitions are replicated to both regions.
- **Elasticsearch**: Requires 3 master-eligible nodes for proper quorum. The voting-only node in Region 2 participates in leader election without storing data.
- **Network Latency Requirement**: This setup assumes **low latency (<15ms)** between the two primary datacenters.

## Key Configuration Files

### 1. `dual-region.yaml` (from `camunda-values.yaml.d/`)

**Purpose**: Core multi-region Zeebe configuration

**Key Settings**:
```yaml
global:
  multiregion:
    regions: 2                        # Number of active regions
  identity:
    auth:
      enabled: false                  # Disables Identity (falls back to demo/demo)
  elasticsearch:
    disableExporter: true             # Custom exporters configured instead

zeebe:
  replicationFactor: 4                # Each partition replicated to all 4 brokers
  env:
    - name: ZEEBE_BROKER_NETWORK_ADVERTISEDHOST
      value: "$(K8S_NAME).$(K8S_NAMESPACE).svc"  # Cross-cluster DNS resolution
    - name: ZEEBE_BROKER_CLUSTER_INITIALCONTACTPOINTS
      value: camunda-zeebe-0.camunda-r0.svc:26502,...  # All brokers across regions
    - name: ZEEBE_BROKER_CLUSTER_MEMBERSHIP_PROBETIMEOUT
      value: 500ms                    # Adjusted for cross-region latency
```

**Disabled Components** (not supported in dual-region):
- Identity
- Identity Keycloak
- Optimize
- Connectors

### 2. `cluster-size-mini-dual-region.yaml`

**Purpose**: Defines minimum viable cluster size for dual-region

```yaml
zeebe:
  clusterSize: 4          # Total brokers (2 per region)
  partitionCount: 1       # Single partition (multiply for production)
  pvcSize: 10Gi
zeebeGateway:
  replicas: 1
```

### 3. `elasticsearch-2.5-region-stretch-cluster.yaml`

**Purpose**: Configures Elasticsearch stretch cluster across 3 locations

**Key Settings**:
```yaml
elasticsearch:
  service:
    type: LoadBalancer              # Required for cross-region communication
  extraConfig:
    cluster.routing.allocation.awareness.attributes: region  # Region-aware sharding
  master:
    replicaCount: 1                 # One master node per region
    extraEnvVars:
      - name: ELASTICSEARCH_CLUSTER_MASTER_HOSTS
        value: "camunda-r0-elasticsearch-master-0 camunda-r1-elasticsearch-master-0 camunda-r2-elasticsearch-master-0"
      - name: ELASTICSEARCH_MINIMUM_MASTER_NODES
        value: "2"                  # Quorum requirement
      - name: ELASTICSEARCH_CLUSTER_HOSTS
        value: "...svc.cluster.local,..."  # Cross-cluster DNS names
```

### 4. Region-Specific YAML Files (`region0.yaml`, `region1.yaml`, `region2.yaml`)

**Purpose**: Define region-specific overrides

```yaml
# region0.yaml
global:
  multiregion:
    regionId: 0                     # MUST start at 0
elasticsearch:
  service:
    loadBalancerIP: <IP>            # Static IP for cross-region access
  extraConfig:
    network.publish_host: <IP>      # External-facing IP
    node.attr.region: 0             # Region attribute for shard awareness

# region2.yaml (tiebreaker)
elasticsearch:
  extraConfig:
    node.roles: [ master, voting_only ]  # No data storage
  master:
    masterOnly: true
```

### 5. `service-per-broker.yaml`

**Purpose**: Creates individual Kubernetes Services for each Zeebe broker

**Why Needed**: Enables cross-cluster DNS resolution for Zeebe brokers. Each broker needs a stable DNS name that can be resolved from the other cluster via CoreDNS forwarding.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: "camunda-zeebe-0"           # Broker-specific service name
spec:
  clusterIP: None                   # Headless service
  publishNotReadyAddresses: true    # Important for cluster formation
  selector:
    statefulset.kubernetes.io/pod-name: camunda-zeebe-0  # Targets specific pod
```

## Makefile Targets

### Root `Makefile` (multi-region/dual-region/)

| Target | Description |
|--------|-------------|
| `make all` | Install Camunda in both region0 and region1 |
| `make clean` | Uninstall Camunda from both regions |
| `make values` | Generate Zeebe Helm values snippets (contact points) |
| `make help` | List available targets |
| `make meld-regions` | (Maintainer) Sync region directories |

### Region `Makefile` (region0/, region1/, region2/)

| Target | Description |
|--------|-------------|
| `make all` | Install Camunda and create broker services |
| `make clean` | Uninstall Camunda and delete broker services |
| `make service-per-broker` | Apply service-per-broker.yaml |
| `make install-camunda` | Helm install Camunda |

### Inherited from `include/camunda.mk`

| Target | Description |
|--------|-------------|
| `make camunda` | Full install (chart download, namespace, install) |
| `make chart` | Add/update Camunda Helm repo |
| `make namespace` | Create Kubernetes namespace |
| `make template` | Generate Helm templates (for debugging) |
| `make dry-run-camunda` | Dry-run installation |

## Configuration Variables (`config.mk`)

Each region has its own `config.mk`:

```makefile
namespace ?= camunda-r0              # Kubernetes namespace (MUST be unique per region)
release ?= camunda                   # Helm release name
chartVersion ?= 11.3.0               # Camunda Helm chart version
chart ?= camunda/camunda-platform --version $(chartVersion)

chartValues ?= \
    "../../../camunda-values.yaml.d/cluster-size-mini-dual-region.yaml" \
    -f "../../../camunda-values.yaml.d/dual-region.yaml" \
    -f "../../../camunda-values.yaml.d/elasticsearch-2.5-region-stretch-cluster.yaml" \
    -f "region0.yaml"
```

## Shell Scripts

### `export_environment_prerequisites.sh`

**Usage**: Source this script to set environment variables:
```bash
. ./export_environment_prerequisites.sh
```

**Variables Set**:
```bash
CAMUNDA_NAMESPACE_0=camunda-r0    # Region 0 namespace
CAMUNDA_NAMESPACE_1=camunda-r1    # Region 1 namespace
HELM_RELEASE_NAME=camunda         # Helm release name
HELM_CHART_VERSION=11.3.0         # Chart version
```

### `generate_zeebe_helm_values.sh`

**Purpose**: Generates the `ZEEBE_BROKER_CLUSTER_INITIALCONTACTPOINTS` value

**Output Example**:
```yaml
- name: ZEEBE_BROKER_CLUSTER_INITIALCONTACTPOINTS
  value: camunda-zeebe-0.camunda-r0.svc.cluster.local:26502,camunda-zeebe-1.camunda-r0.svc.cluster.local:26502,camunda-zeebe-0.camunda-r1.svc.cluster.local:26502,camunda-zeebe-1.camunda-r1.svc.cluster.local:26502

- name: ZEEBE_BROKER_EXPORTERS_ELASTICSEARCHREGION0_ARGS_URL
  value: http://camunda-elasticsearch-master-hl.camunda-r0.svc.cluster.local:9200

- name: ZEEBE_BROKER_EXPORTERS_ELASTICSEARCHREGION1_ARGS_URL
  value: http://camunda-elasticsearch-master-hl.camunda-r1.svc.cluster.local:9200
```

## Prerequisites for Multi-Region Deployment

### Network Requirements

1. **VPC Peering or Transit Gateway**: Both regions must have network connectivity
2. **Non-overlapping CIDR Blocks**: VPC and Pod CIDR ranges must not conflict
3. **Security Groups**: Allow traffic on ports:
   - `26500`: Zeebe Gateway gRPC
   - `26501`: Zeebe Command API
   - `26502`: Zeebe Internal Cluster Communication
   - `9200`: Elasticsearch HTTP
   - `9300`: Elasticsearch Transport

### DNS Requirements

**CoreDNS Configuration**: Each cluster must forward DNS queries for the other region's namespace:

```
# In Region 0 CoreDNS ConfigMap
camunda-r1.svc.cluster.local:53 {
    errors
    cache 30
    forward . <REGION_1_COREDNS_IPS> {
        force_tcp
    }
}
```

### IP Configuration

The `<IP>` placeholders in region YAML files must be replaced with:
- Static/Elastic IPs for LoadBalancer services
- IPs routable from the other region via VPC peering

## Deployment Workflow

### Step 1: Configure Network Infrastructure
```bash
# Establish VPC peering between regions
# Configure route tables
# Update security groups
```

### Step 2: Configure CoreDNS
```bash
# Get DNS endpoints from each cluster
kubectl get endpoints kube-dns -n kube-system

# Update CoreDNS ConfigMap in each cluster
kubectl edit configmap coredns -n kube-system
```

### Step 3: Update Configuration
```bash
# Edit region-specific YAML files with actual IPs
vi region0/region0.yaml
vi region1/region1.yaml
vi region2/region2.yaml

# Edit config.mk if namespace names need changing
vi region0/config.mk
vi region1/config.mk
```

### Step 4: Generate Values
```bash
. ./export_environment_prerequisites.sh
./generate_zeebe_helm_values.sh
# Copy output to dual-region.yaml if different from defaults
```

### Step 5: Deploy
```bash
# Deploy to all regions
make all

# Or deploy to individual regions
cd region0 && make all
cd region1 && make all
cd region2 && make all
```

### Step 6: Verify
```bash
# Check Zeebe cluster topology
kubectl port-forward svc/camunda-zeebe-gateway 26500:26500 -n camunda-r0
zbctl --address localhost:26500 --insecure status

# Expected: 4 brokers, distributed across regions
```

## Troubleshooting Guide for AI Agents

### Common Issues

1. **Zeebe brokers can't find each other**
   - Check CoreDNS configuration
   - Verify VPC peering routes
   - Test with: `kubectl exec dnsutils -- nslookup camunda-zeebe-0.camunda-r1.svc.cluster.local`

2. **Elasticsearch cluster not forming**
   - Check LoadBalancer IPs are correctly configured
   - Verify all 3 master nodes can communicate
   - Check: `kubectl logs camunda-elasticsearch-master-0 -n camunda-r0`

3. **Pods stuck in Pending**
   - Check StorageClass exists: `kubectl get sc`
   - Verify PVC binding: `kubectl get pvc`

4. **Network timeout errors**
   - Verify security group rules
   - Check route table configurations
   - Test connectivity: `kubectl exec dnsutils -- ping <other-region-pod-ip>`

### Diagnostic Commands

```bash
# Check Zeebe cluster status
zbctl --address localhost:26500 --insecure status

# Check Elasticsearch cluster health
curl http://<elasticsearch-ip>:9200/_cluster/health?pretty

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test cross-cluster DNS
kubectl exec dnsutils -- nslookup camunda-zeebe-0.camunda-r1.svc.cluster.local
```

## Related Files (External to this Directory)

| File Path | Purpose |
|-----------|---------|
| `camunda-values.yaml.d/dual-region.yaml` | Core dual-region Zeebe configuration |
| `camunda-values.yaml.d/cluster-size-mini-dual-region.yaml` | Cluster sizing for dual-region |
| `camunda-values.yaml.d/elasticsearch-2.5-region-stretch-cluster.yaml` | Elasticsearch stretch cluster config |
| `include/camunda.mk` | Common Makefile targets for Camunda installation |

## Version Information

- **Helm Chart Version**: 11.3.0 (managed by Renovate)
- **Camunda Version**: Corresponds to Helm chart version
- **Supported Zeebe Protocol**: Raft-based consensus

## Limitations

As documented in Camunda's official docs, the following components are **NOT supported** in dual-region:
- Identity / Keycloak (disabled)
- Optimize (disabled)
- Connectors (disabled)

These are disabled in `dual-region.yaml` and fall back to basic auth (demo/demo).


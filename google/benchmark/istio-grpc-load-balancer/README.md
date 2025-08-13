# Istio Ambient Mesh with gRPC Load Balancing for Zeebe Gateway

This directory contains configuration files for setting up Istio Ambient Mesh with optimized gRPC load balancing for Camunda Zeebe Gateway connections.

## Overview

The setup provides:
- **Istio Ambient Mesh** for transparent service mesh capabilities
- **Waypoint Proxy** for L7 traffic management and load balancing
- **gRPC-optimized load balancing** using `LEAST_REQUEST` strategy
- **Custom infrastructure configuration** for waypoint proxy resources and node placement

## Files Description

### Core Configuration Files

#### `Makefile`
Makefile with targets for installing and configuring Istio:
- `install-istio`: Installs Istio with ambient profile and Gateway API CRDs
- `istio-waypoint`: Deploys waypoint defaults and waypoint proxy
- `istio-destination-rule`: Applies the service and destination rule configurations
- `uninstall-istio`: Removes Istio and cleans up resources
- `clean-istio-waypoint`: Removes waypoint proxy and defaults
- `clean-istio-destination-rule`: Removes service and destination rule

#### `camunda-zeebe-gateway-grpc.yml`
Kubernetes Service configuration for the Zeebe Gateway with Istio annotations:
- Exposes port 26500 with gRPC protocol
- Labels the service for ambient mesh inclusion
- Configures the service to use the waypoint proxy

#### `istio-waypoint.yaml`
Istio Gateway (waypoint proxy) configuration:
- Defines a waypoint proxy for L7 traffic management
- Configured for mesh traffic on port 15008 using HBONE protocol
- Allows routes from the same namespace

#### `istio-waypoint-defaults.yaml`
ConfigMap defining default infrastructure settings for waypoint proxies:
- Sets resource requests/limits for waypoint proxy containers
- Configures node selector for specific GKE node pools
- Applied automatically to all gateways using the `istio-waypoint` class

#### `istio-destination-rule-gateway.yaml`
DestinationRule for optimizing gRPC load balancing:
- Configures `LEAST_REQUEST` load balancing strategy
- Targets the Zeebe Gateway service specifically

## Setup Instructions

### 1. Install Istio with Ambient Mesh
```bash
make install-istio
```

### 2. Deploy Waypoint Proxy and Defaults
```bash
make istio-waypoint
```

### 3. Configure Zeebe Gateway Service and Load Balancing
```bash
make istio-destination-rule
```

## Client Application Requirements

### ⚠️ Important: Client Pod Configuration

**Any Zeebe client application** connecting to the `camunda-zeebe-gateway-grpc` service **must** be configured with the following Kubernetes label:

```yaml
metadata:
  labels:
    istio.io/dataplane-mode: ambient
```

**Example StatefulSet/Deployment:**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: zeebe-client-app
spec:
  template:
    metadata:
      labels:
        app: zeebe-client
        istio.io/dataplane-mode: ambient  # ← REQUIRED
    spec:
      containers:
      - name: client
        image: your-zeebe-client:latest
        env:
        - name: ZEEBE_ADDRESS
          value: "camunda-zeebe-gateway-grpc:26500"
```

### Alternative: Namespace-Level Configuration

Instead of labeling individual pods, you can enable ambient mesh for the entire namespace:

```bash
kubectl label namespace <client-namespace> istio.io/dataplane-mode=ambient
```

## How It Works

1. **Ambient Mesh**: Provides transparent Layer 4 connectivity and security
2. **Waypoint Proxy**: Handles Layer 7 features like advanced load balancing and routing
3. **gRPC Optimization**: The `LEAST_REQUEST` load balancer distributes requests to the least busy Zeebe Gateway instance
4. **Resource Management**: Waypoint proxies are automatically configured with appropriate CPU/memory limits and scheduled on specific node pools

## Load Balancing Strategy

The configuration uses `LEAST_REQUEST` load balancing, which is optimal for gRPC connections because:
- It considers the current load on each backend
- Prevents hot-spotting on individual gateway instances
- Provides better distribution for long-lived gRPC connections compared to round-robin

## Troubleshooting

### Waypoint Proxy Issues
- Check if the ConfigMap is applied in the `istio-system` namespace
- Verify the waypoint proxy has sufficient resources (check logs for OOMKilled events)
- Ensure the node selector matches available nodes in your cluster

### Client Connection Issues
- Verify the client pod has the `istio.io/dataplane-mode: ambient` label
- Check that the client is in a namespace that allows connections to the waypoint
- Confirm the service endpoints are healthy: `kubectl get endpoints camunda-zeebe-gateway-grpc`

### Load Balancing Verification
```bash
# Check if DestinationRule is applied
kubectl get destinationrule

# Verify waypoint proxy status
kubectl get gateways.gateway.networking.k8s.io -n camunda

# Check waypoint proxy pods
kubectl get pods -n camunda -l gateway.networking.k8s.io/gateway-name=waypoint
```

## Cleanup

To remove all Istio components:
```bash
make uninstall-istio
```

To remove waypoint proxy and defaults:
```bash
make clean-istio-waypoint
```

To remove service and destination rule:
```bash
make clean-istio-destination-rule
```

## References

- [Istio Ambient Mesh Documentation](https://istio.io/latest/docs/ambient/)
- [Gateway API Documentation](https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/)
- [Camunda Zeebe Documentation](https://docs.camunda.io/docs/components/zeebe/)

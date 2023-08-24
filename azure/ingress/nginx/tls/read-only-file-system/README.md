# Restricted Security Context

This profile is created to set up a Camunda 8 cluster with the below security context applied to all pods. 
This is required in some environments as a security best practise

```allowPrivilegeEscalation: false
privileged: false
readOnlyRootFilesystem: true
runAsNonRoot: true
runAsUser: 1000 
```

> **NOTE** : In case of applying `runAsNonRoot: true` for Elastic Search, this would not work, unless the node on which ES is setup already has the `vm.max_map_count` set to 262144

This particular kernel parameter `vm.max_map_count` is forbidden from being edited via the security context. Furthermore, Elasticsearch provides an initContainer, which configures this kernel parameter on the host prior to execution but this requires to run as root.

More details in the ES DOCS - https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html

#!/usr/bin/env python

import distutils.spawn
import json
import os
from subprocess import check_call,check_output
from sys import exit
from time import sleep

# Before running the script, fill in appropriate values for all the parameters
# above the dashed line.

# Fill in the `contexts` map with the regions of your clusters and their
# corresponding kubectl context names.
#
# To get the names of your kubectl "contexts" for each of your clusters, run:
#   kubectl config get-contexts
#
# format:
# contexts = {
#    region_name: context_name,
# }
#
# example:
# contexts = {
#    'us-east1': 'gke_camunda-researchanddevelopment_us-east1_falko-region-0',
#    'europe-west1': 'gke_camunda-researchanddevelopment_europe-west1_falko-region-1',
# }
# TODO generate kubectl contexts via make using pattern: gke_$(project)_$(region)_$(clusterName)
contexts = {
    'us-east1': 'gke_camunda-researchanddevelopment_us-east1_falko-region-0',
    'europe-west1': 'gke_camunda-researchanddevelopment_europe-west1_falko-region-1',
}

# Fill in the number of Zeebe brokers per region,
# i.e. clusterSize/regions as defined in camunda-values.yaml
number_of_zeebe_brokers_per_region = 4

# Path to directory generated YAML files.
generated_files_dir = './generated'

# ------------------------------------------------------------------------------

# First, do some basic input validation.
if len(contexts) == 0:
    exit("must provide at least one Kubernetes cluster in the `contexts` map at the top of the script")

for zone, context in contexts.items():
    try:
        check_call(['kubectl', 'get', 'pods', '--context', context])
    except:
        exit("unable to make basic API call using kubectl context '%s' for cluster in zone '%s'; please check if the context is correct and your Kubernetes cluster is working" % (context, zone))

# Set up the necessary directory. Ignore errors because they may already exist.
try:
    os.mkdir(generated_files_dir)
except OSError:
    pass


# For each cluster, create a load balancer to its DNS pod.
for zone, context in contexts.items():
    check_call(['kubectl', 'apply', '-f', 'dns-lb.yaml', '--context', context])

# Set up each cluster to forward DNS requests for zone-scoped namespaces to the
# relevant cluster's DNS server, using load balancers in order to create a
# static IP for each cluster's DNS endpoint.
dns_ips = dict()
for zone, context in contexts.items():
    external_ip = ''
    while True:
        external_ip = check_output(['kubectl', 'get', 'svc', 'kube-dns-lb', '--namespace', 'kube-system', '--context', context, '--template', '{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}']).decode("UTF-8")
        if external_ip:
            break
        print('Waiting for DNS load balancer IP in %s...' % (zone))
        sleep(10)
    print ('DNS endpoint for zone %s: %s' % (zone, external_ip))
    dns_ips[zone] = external_ip

# Update each cluster's DNS configuration with an appropriate configmap. Note
# that we have to leave the local cluster out of its own configmap to avoid
# infinite recursion through the load balancer IP. We then have to delete the
# existing DNS pods in order for the new configuration to take effect.
for zone, context in contexts.items():
    remote_dns_ips = dict()
    for z, ip in dns_ips.items():
        if z == zone:
            continue
        remote_dns_ips[z+'.svc.cluster.local'] = [ip]
        remote_dns_ips[z+'-failover.svc.cluster.local'] = [ip]
    print(remote_dns_ips)
    config_filename = '%s/dns-configmap-%s.yaml' % (generated_files_dir, zone)
    with open(config_filename, 'w') as f:
        f.write("""\
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    %s
""" % (json.dumps(remote_dns_ips)))
    check_call(['kubectl', 'apply', '-f', config_filename, '--namespace', 'kube-system', '--context', context])
    check_call(['kubectl', 'delete', 'pods', '-l', 'k8s-app=kube-dns', '--namespace', 'kube-system', '--context', context])

# Generate ZEEBE_BROKER_CLUSTER_INITIALCONTACTPOINTS
join_addrs = []
for zone in contexts:
    for i in range(number_of_zeebe_brokers_per_region):
        join_addrs.append('camunda-zeebe-%d.camunda-zeebe.%s.svc.cluster.local:26502' % (i, zone))
join_str = ','.join(join_addrs)
print(join_str)

# Generate ZEEBE_BROKER_EXPORTERS_ELASTICSEARCH2_ARGS_URL e.g. http://elasticsearch-master-headless.us-east1.svc.cluster.local:9200
elastic_urls = {}
for zone, context in contexts.items():
    print('http://elasticsearch-master-headless.%s.svc.cluster.local:9200' % (zone))

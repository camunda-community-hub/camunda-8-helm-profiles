#!/usr/bin/env python

from shutil import rmtree
from subprocess import call

# Before running the script, fill in appropriate values for all the parameters
# above the dashed line. You should use the same values when tearing down a
# cluster that you used when setting it up.

# To get the names of your kubectl "contexts" for each of your clusters, run:
#   kubectl config get-contexts
contexts = {
    'us-east1': 'gke_infrastructure-experience_us-east1_falko-region-0',
    'europe-west1': 'gke_infrastructure-experience_europe-west1_falko-region-1',
}

certs_dir = './certs'
ca_key_dir = './my-safe-directory'
generated_files_dir = './generated'

# ------------------------------------------------------------------------------

# Delete each cluster's special region-scoped namespace, which transitively
# deletes all resources that were created in the namespace, along with the few
# other resources we created that weren't in that namespace
for region, context in contexts.items():
    call(['kubectl', 'delete', 'namespace', region, '--context', context])
    # call(['kubectl', 'delete', 'secret', 'cockroachdb.client.root', '--context', context])
    # call(['kubectl', 'delete', '-f', 'external-name-svc.yaml', '--context', context])
    call(['kubectl', 'delete', '-f', 'dns-lb.yaml', '--context', context])
    call(['kubectl', 'delete', 'configmap', 'kube-dns', '--namespace', 'kube-system', '--context', context])
    # Restart the DNS pods to clear out our stub-domains configuration.
    call(['kubectl', 'delete', 'pods', '-l', 'k8s-app=kube-dns', '--namespace', 'kube-system', '--context', context])

try:
    rmtree(certs_dir)
except OSError:
    pass
try:
    rmtree(ca_key_dir)
except OSError:
    pass
try:
    rmtree(generated_files_dir)
except OSError:
    pass

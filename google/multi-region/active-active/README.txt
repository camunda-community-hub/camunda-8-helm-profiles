
make templates to get the templates in the region folder
Reduce the number of replicas in the zeebe statefullset to half.
Make namespace
kubectl apply -f camunda-platform --recursive -n camunda

check status from the web console : 
gcloud container clusters get-credentials cdame-region-1 --zone europe-west4-b --project camunda-researchanddevelopment  && kubectl exec camunda-zeebe-gateway-6d766454c8-jnrxz --namespace camunda -c zeebe-gateway -- zbctl status --insecure
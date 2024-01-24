
gcloud compute instances describe $(kubectl get nodes -o name --output jsonpath="{.items[0].metadata.name}") --zone europe-west1-b --format="get(tags.items)"

gcloud compute instances describe $(kubectl get nodes -o name --output jsonpath="{.items[0].metadata.name}") --zone us-east1-b --format="get(tags.items)"

gcloud compute firewall-rules create camunda-multi-region \
    --allow=tcp:9600,tcp:26501,tcp:26502,tcp:9300,tcp:9200,udp:26502,udp:9200,udp:9300 \
    --source-ranges="10.56.0.0/14,10.16.0.0/14" \
    --target-tags="gke-falko-region-0-7218183c-node,gke-falko-region-1-01ced8cf-node" \
    --description="Camunda cross-cluster TCP and UDP traffic" \
    --project infrastructure-experience

# ---

gcloud storage buckets create gs://camunda-hackweek-elasticsearch-backup --project infrastructure-experience

gcloud iam service-accounts create camunda-hackweek-es-backup \
    --description="Service account for camunda-hackweek-elasticsearch-backup bucket" \
    --project infrastructure-experience


gcloud projects add-iam-policy-binding infrastructure-experience \
    --member="serviceAccount:camunda-hackweek-es-backup@infrastructure-experience.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud iam service-accounts keys create ~/Downloads/camunda-hackweek-es-backup-key.json \
    --iam-account=camunda-hackweek-es-backup@infrastructure-experience.iam.gserviceaccount.com

gcloud compute firewall-rules delete camunda-multi-region \
  --project infrastructure-experience


kubectl exec camunda-elasticsearch-master-0 -n us-east1 -c elasticsearch -- curl -i camunda-zeebe-0:9600/actuator/exporting/pause -XPOST
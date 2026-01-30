# Provision GCP Google Kubernetes Engine (GKE) 
This will provision the following:
- A Google GKE cluster

## Prerequisites
- An GCP account with permissions to create GKE cluster. Use the following make target if convenient. 

```shell
$> make check-gcloud
Checking gcloud configuration...
✅ gcloud is installed and configured: camunda-researchanddevelopment
```
- [Google Cloud Command Line Interface (gclound CLI)](https://cloud.google.com/cli) installed and configured.
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.
- [eksctl](https://eksctl.io/) installed.

## Install
```sh
make
```

## Uninstall
```sh
make clean
```


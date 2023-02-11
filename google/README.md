# Helm Profiles for Camunda 8 on Google Cloud Platform (GCP)

Create a Camunda 8 self-managed Kubernetes Cluster in 3 Steps:

Step 1: Setup some [global prerequisites](../README.md#prerequisites)

Step 2: Setup command line tools for GCP:

1. Verify `gcloud` is installed (https://cloud.google.com/sdk/docs/install-sdk)

       gcloud --help

2. Make sure you are authenticated. If you don't already have one, you'll need to sign up for a new Google Cloud Account. Then, run the following command and then follow the instructions to authenticate via your browser.

       gcloud auth login

3. Setup the gke-cloud-auth-plugin 

       gcloud components install gke-gcloud-auth-plugin

6. Go into one of the profiles in the `google` folder and use the `Makefile` to create a GKE cluster

e.g. `cd` into the `ingress/nginx/tls` directory and see the [README.md](./ingress/nginx/tls/README.md) for more.

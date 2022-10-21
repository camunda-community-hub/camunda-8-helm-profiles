# Helm Profiles for Camunda 8 on Google Cloud Platform (GCP)

The `google` folder contains generic artifacts which can be used with any of the specific Google profiles.

The sub folders contains the artifacts for specific configurations 
- [ingress-nginx](ingress-nginx): Use Nginx ingress controller

# Installation of Kubernetes and Camunda Platform 8

Create a Camunda 8 self-managed Kubernetes Cluster in 3 Steps:

Step 1: Setup some [global prerequisites](../README.md#global-prerequisites)

Step 2: Setup command line tools for GCP:

1. Verify `gcloud` is installed (https://cloud.google.com/sdk/docs/install-sdk)

       gcloud --help

2. Make sure you are authenticated. If you don't already have one, you'll need to sign up for a new
   Google Cloud Account. Then, run the following command and then follow the instructions to authenticate via your browser.

       $ gcloud auth login

3. Go into one of the profiles in the `google` folder and the `Makefile` to create a GKE cluster

e.g. `cd` into the `ingress-nginx` directory

Edit the `Makefile` and set the following bash variables so that they are appropriate for your specific environment.

    project ?= <YOUR PROJECT>
    clusterName ?= <YOUR CLUSTER NAME>
    region ?= us-east1-b
    machineType ?= n1-standard-16

Run `make kube-metrics-all` to create a Google Kubernetes cluster and install Camunda.

If you just want (re-)install Camunda on an existing Kubernetes cluster
you can run `make` (without any targets).
Check out the shell completion offered by `make` for alternative targets.
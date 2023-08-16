# Helm Profiles for Camunda 8 on Google Cloud Platform (GCP)

Create a Camunda 8 self-managed Kubernetes Cluster using the following steps: 

Step 1: Setup some [global prerequisites](../README.md#prerequisites)

Step 2: Setup command line tools for GCP:

1. Verify `gcloud` is installed (https://cloud.google.com/sdk/docs/install-sdk)

       gcloud --help

2. Make sure you are authenticated. If you don't already have one, you'll need to sign up for a new Google Cloud Account. Then, run the following command and then follow the instructions to authenticate via your browser.

       gcloud auth login

3. Setup the gke-cloud-auth-plugin 

       gcloud components install gke-gcloud-auth-plugin

4. Check installation

       gcloud components list
       gcloud components list | grep gke-gcloud-auth-plugin

5. Go into one of the profiles in the `google` folder and use the `Makefile` to create a GKE cluster

    ```
    # Edit the files inside `config` director with values specific to your installation
    
    make login         # ensure you are logged into Google Cloud
    make kube          # establish kubernetes cluster on Google Cloud (5-10 minutes run) 

    # Default            Simple Camunda 8 you must operate with port-forward
    make all           # deploying camunda 8 as "simple" individual "pods". Useful for developer. 
    kubectl get pods   # List running kubernetes 'deployments' (running at Google Cloud) 
    
    # .. have a lot of fun..
   
    make clean         # remove Camunda 8, but "kube" is not deleted
    make clean-kube    # remove kube (save money)
    ```

6. Selecting configuration

Sub configurations at Google 
* [Ingress/tls](./ingress/nginx/tls/README.md) : nginx+TLS  `cd` into the `ingress/nginx/tls` directory.
* [Benchmark](./benchmark/README.md) :  benchmark `cd` into the `benchmark` directory.
* [Keycloak](./keycloak/README.md) : keycloak  `cd` into the `keycloak` directory.
* [Keycloak/camunda](./keycloak/camunda/README.md) : keycloak+Camunda  `cd` into the `keycloak` directory.
* Default: Directory 'google' (see above) and see make's comments in terminal

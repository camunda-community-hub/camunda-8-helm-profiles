# Helm Profiles for Camunda 8 on Microsoft Azure

Create a Camunda 8 self-managed Kubernetes Cluster in 3 Steps:

Step 1: Setup some [global prerequisites](../README.md#prerequisites)

Step 2: Setup command line tools for Azure: 

1. Verify that the `az` cli tool is installed (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

       $ az version
       {
        "azure-cli": "2.38.0",
        "azure-cli-core": "2.38.0",
        "azure-cli-telemetry": "1.0.6",
        "extensions": {}
       }

2. Make sure you are authenticated. If you don't already have one, you'll need to sign up for a new Azure Account. Then, run the following command and then follow the instructions to authenticate via your browser.

       $ az login

> **Tip** If you or your company uses SSO to sign in to Microsoft, first, open a browser and sign in
> to your Azure/Microsoft account. Then try doing the `az login` command again.

3. Go into one of the profiles inside this `azure` folder and use the `Makefile` to create a AKS cluster. 

e.g. `cd` into the `ingress/nginx/tls` directory and see the [README.md](ingress/nginx/tls/README.md) for more.



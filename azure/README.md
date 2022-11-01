# Camunda 8 Helm Profile: Azure

The azure folder contains generic artifacts which can be used with any of the specific Azure profiles. 

The sub folders contains the artifacts for specific configurations. 

See README inside sub folders for more info:
- ingress-nginx/tls: Use nginx ingress controller with azure fqdn and enabled tls. If you're just getting started, start with this profile. 
- ingress-agic: Use Azure Application Gateway as an ingress controller

## Basic Prerequisites

Make sure you meet [these prerequisites](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/master/README.md#prerequisites).

## Microsoft Azure Prerequisites

1. Verify that the `az` cli tool is installed (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

       $ az version
       {
        "azure-cli": "2.38.0",
        "azure-cli-core": "2.38.0",
        "azure-cli-telemetry": "1.0.6",
        "extensions": {}
       }

2. Make sure you are authenticated. If you don't already have one, you'll need to sign up for a new
   Azure Account. Then, run the following command and then follow the instructions to authenticate via your browser.

       $ az login

> **Tip** If you or your company uses SSO to sign in to Microsoft, first, open a browser and sign in
> to your Azure/Microsoft account. Then try doing the `az login` command again.




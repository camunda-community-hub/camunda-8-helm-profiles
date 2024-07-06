# Helm Profiles for Camunda 8 on Openshift

This folder contains scripts to use as reference for installing Camunda in Openshift 

Here are the steps to setup a Camunda Local environment. Of course, your environment will differ slightly. Feel free to 
adjust these scripts as needed. 

## Create a Openshift Cluster

There are several options for provisioning an Openshift Kubernetes Cluster. This is outside the scope of this document, 
but one option is to use [Instal Openshift Local](https://developers.redhat.com/products/openshift-local/overview). 

## Make

All the steps here are implemented using `make`. If you'd prefer not to use `make`, you can also find the shell commands
to run by looking inside [openshift.mk](openshift.mk) file.

These commands should work across Windows / Linux / Mac. If you're running Windows, use the Windows Subsystem for Linux as 
most of these commands won't work in the Windows command or powershell terminals. 

## Get Connection details

Run `make creds` to get the credentials to connect to your cluster. 

## Set environment variables 

Edit the values inside [set-env-openshift.sh](set-env-openshift.sh) to be correct for your environment.

Run `. ./set-env-openshift.sh` to set environment variables into your current terminal session. 

## Configure Environment

Run `make set-config` to set disk size and memory. These are the settings that worked on my laptop. You may need to experiment with different sizing based on your environment and requirements. 

## Restart Environment

Run `make restart` to ensure the config changes are applied. I've found that openshift can be delicate. It sometimes takes several restarts to get a successfully running environment. 

## Access Web Console

Run `make console` to open a browser and navigate to the Openshift Web Console. 

## Install Camunda

Run `make camunda-values-openshift.yaml` to generate a values.yaml file. Edit the file for your requirements. 

Run `make camunda` to install camunda using `camunda-values-openshift.yaml`. 

## Uninstall

This step will also remove `camunda-values-openshift.yaml` so make a backup if you don't want to lose it. 

Run `make clean-camunda` to remove the camunda installation. 

Remember to manually delete the PVs via the web console. 

# How to Configure Re-encrypt Routes

## Keycloak tls

https://github.com/bitnami/charts/tree/main/bitnami/keycloak#keycloak-parameters

Here a link to steps to create a K8s secret with everything needed:

https://github.com/bitnami/charts/blob/b5074584ed43b0ac54ec9883a12da274ee64b6e0/bitnami/keycloak/values.yaml#L151

Create a certificate containing key and cert:

```shell
kubectl create secret generic keycloak-tls-secret --from-file=./keycloak.truststore.jks --from-file=./keycloak.keystore.jks
```

See the `IdentityKeycloak` section inside [values-identity-reencrypt.yaml](values/values-identity-reencrypt.yaml)

# Helm Profiles for Camunda 8 on Openshift

This folder contains scripts to use as a reference for installing Camunda in a Openshift Local environment. Of course, every 
environment will differ slightly and these scripts should be adjusted as needed. 

## Create a Openshift Cluster

[Instal Openshift Local](https://developers.redhat.com/products/openshift-local/overview). 

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

Run `make restart` to ensure the config changes are applied. I've found that it sometimes takes several restarts to get a successfully running environment. 

## Access Web Console

Run `make console` to open a browser and navigate to the Openshift Web Console. 

## Install Camunda

There are several example `values.yaml` files inside the [values](values) directory: 

- [values-dev.yaml](values/values-dev.yaml) provides a minimum environment without authentication disabled
- [values-identity-edge.yaml](values/values-identity-edge.yaml) provides a full environment suitable for use with Edge Routes
- [values-identity-reencrypt.yaml](values/values-identity-reencrypt.yaml) provides a full environment suitable for Re-encrypt Routes

If you'd like to use make, see the Make target named `camunda-values-openshift.yaml`. This target will simply copy one of those files into 
the `openshift` directory and rename it to `camunda-values-openshift.yaml`.

Run `make camunda` to install camunda using `camunda-values-openshift.yaml`. 

## Uninstall

This step will also remove `camunda-values-openshift.yaml` so make a backup if you don't want to lose it. 

Run `make clean-camunda` to remove the camunda installation. 

Remember to manually delete the PVs via the web console. 

# How to Configure Re-encrypt Routes

## Create SSL Certificates

> [!CAUTION]
> The certificates and private keys found inside the [certs](certs) directory are provided for reference and should not be used in production. You should never share a production private key.

You'll need the following for each service to be exposed via Re-encrypt Routes: 

1. A "backend" certificate and corresponding private key. These will be added to a java keystore and used to serve encrypted traffic from the backend kubernetes services (such as keycloak, identity, tasklist, operate, etc). This example uses a single [backend.test.crt](certs/backend.test.crt) and [dave.test.key](certs/dave.test.key) to encrypt traffic to backend k8s services
2. A "frontend" certificate and corresponding private key. These are used encrypt traffic from the browser to the Openshift Ingress. This example uses a single [frontend.test.crt](certs/frontend.test.crt) and [dave.test.key](certs/dave.test.key)
3. The public CA certificate used to issue the certs mentioned above. This example uses [myCA.pem](certs/myCA.pem)
4. A keystore containing the backend cert and key. This example uses [keycloak.keystore.jks](certs/keycloak.keystore.jks)
5. A truststore containing the public CA cert. This is used so clients trust the backend certs. This example uses [keycloak.truststore.jks](certs/keycloak.truststore.jks)

## Keycloak

### Backend tls

Here's a list of parameters used to configure tls in Keycloak: 

https://github.com/bitnami/charts/tree/main/bitnami/keycloak#keycloak-parameters

Here a link to steps to create a K8s secret with everything needed:

https://github.com/bitnami/charts/blob/b5074584ed43b0ac54ec9883a12da274ee64b6e0/bitnami/keycloak/values.yaml#L151

1. Create a keystore containing the public certificate and private key. 
2. Create a truststore containing the public CA certificate.  
3. Create a secret containing the keystore and truststore. There are several ways to do this, here's the command I used:   

```shell
kubectl create secret generic keycloak-tls-secret --from-file=./keycloak.truststore.jks --from-file=./keycloak.keystore.jks
```

4. Configure Keycloak to listen on port 443 for tls and use the k8s secret to encrypt backend traffic. See the `IdentityKeycloak` section inside [values-identity-reencrypt.yaml](values/values-identity-reencrypt.yaml)

### Frontend

Create a Route similar to this: 

```yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: camunda-keycloak
  namespace: camunda
  labels:
    app: camunda-platform
spec:
  host: <YOUR_HOST>
  to:
    kind: Service
    name: camunda-keycloak
    weight: 100
  port:
    targetPort: https
  tls:
    termination: reencrypt
    certificate: |
      -----BEGIN CERTIFICATE-----
      <Copy Public frontend certificate here>
      -----END CERTIFICATE-----
    key: |
      -----BEGIN PRIVATE KEY-----
      <Copy frontend private key here>
      -----END PRIVATE KEY-----
    caCertificate: |
      -----BEGIN CERTIFICATE-----
      <Copy public CA Certificate used to sign frontend cert here>  
      -----END CERTIFICATE-----
    destinationCACertificate: |
      -----BEGIN CERTIFICATE-----
      <Copy public CA Certificate used to sign backend cert here> 
      -----END CERTIFICATE-----
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
```

## Identity

### Allow Identity to connect to Keycloak over tls

After enabling tls on the keycloak backend service, Identity can no longer connect. To fix this, configure Identity to use a truststore which includes the CA certificate that signed the keycloak backend service cert.  

See the `identity` section of [values-identity-reencrypt.yaml](values/values-identity-reencrypt.yaml) for reference.

### Backend tls

Follow the steps [here](https://docs.camunda.io/docs/self-managed/identity/user-guide/configuration/making-identity-production-ready/#enabling-tls) to enable TLS. 

See the `identity` section of [values-identity-reencrypt.yaml](values/values-identity-reencrypt.yaml) for reference. 

Note that the identity app will list on 8443 and so the corresponding `camunda-identity` servce also needs to be updated to route traffic from 443 to 8443 (instead of from 80 to 8080). Also note that the values file was updated so that the http probes work against the new https scheme. 

### Frontend tls

Create a Route similar to this:

```yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: camunda-identity
  namespace: camunda
  labels:
    app: camunda-platform
spec:
  host: <YOUR_HOST>
  to:
    kind: Service
    name: camunda-identity
    weight: 100
  port:
    targetPort: https
  tls:
    termination: reencrypt
    certificate: |
      -----BEGIN CERTIFICATE-----
      <Copy Public frontend certificate here>
      -----END CERTIFICATE-----
    key: |
      -----BEGIN PRIVATE KEY-----
      <Copy frontend private key here>
      -----END PRIVATE KEY-----
    caCertificate: |
      -----BEGIN CERTIFICATE-----
      <Copy public CA Certificate used to sign frontend cert here>  
      -----END CERTIFICATE-----
    destinationCACertificate: |
      -----BEGIN CERTIFICATE-----
      <Copy public CA Certificate used to sign backend cert here> 
      -----END CERTIFICATE-----
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
```

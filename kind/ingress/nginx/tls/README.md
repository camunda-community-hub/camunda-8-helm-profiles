# Camunda 8 Helm Profile: Ingress NGINX for Kind with TLS Certificates

> **Note**  This profile is still a work in progress. For latest progress, please see this [Github Issue](https://github.com/camunda-community-hub/camunda-8-helm-profiles/issues/41)

Follow the instructions from the [main Kind readme](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/webmodeler-kind-update/kind/README.md) but run from this directory to enable ingress and TLS.

Prerequisites

Install JQ

Install cfssl & cfssljosn (this is only needed if you want a working cert for zeebe clients such as zbctl)
https://blog.cloudflare.com/introducing-cfssl-1-2/
https://formulae.brew.sh/formula/cfssl
https://github.com/cloudflare/cfssl#installation


Create the cluster
```
make kube
```

Install Camunda
Run the Make command with your docker registry credentials
```
make certEmail=<email> camundaDockerRegistryEmail=<email> camundaDockerRegistryUsername=<your_user>  camundaDockerRegistryPassword=<password>
```

NOTE: To ensure you can access all the apps with a self signed certificate on your localhost run chrome with the following command.

```
open /Applications/Google\ Chrome.app --args -unsafely-treat-insecure-origin-as-secure=https://127.0.0.1.nip.io/ -user-data-dir=/tmp/foo
```

Use Web Modeler

You need to get the secret from KeyCloak by going to the zeebe client in keycloak then the `Credentials` tab.

First get the password for keycloak login
```
make keycloak-password
```

Setup the connection to zeebe so webmodeler can deploy and run BPMN

![Keycloak Zeebe Client Secret](https://github.com/camunda-community-hub/camunda-8-helm-profiles/blob/7bc8352e6b2ff7ccad64821541fd61f1593230d4/docs/images/webmodeler-zeebe-connect.png?raw=true)


Connect to the zeebe with zbctl
```
zbctl status --address 127.0.0.1.nip.io:443 --certPath ./certs/signed-client.crt
```

# TLS Certificates and Camunda 8

This folder contains notes, suggestions, and guidance for provisioning and configuring TLS Certificates and Camunda 8

## Setup TLS encryptiong for network traffic between Camunda Components

Some environments (such as Openshift `reencypt` routes) require backend k8s pods to communicate with tls encryption enabled. 

These components typically communicate to k8s services via k8s dns. 

For example, Operate connects to the zeebe gateway via the k8s service that is named `camunda-zeebe-gateway`. 

In kubernetes, this service is accessible via a domain name of `camunda-zeebe-gateway.namespace.svc.local`

The following steps show how to provision self signed certificates which can be used to tls encrypt traffic sent to the zeebe gateway. 

### 1. Create a Custom self-signed Certificate Authority (CA)

I used the following commands to create a Certificate Authority.

```shell
# Create a public private key pair
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ca/ca.key -out ca/ca.crt -subj "/CN=c8sm/O=c8sm"
# Convert the keys to base64 encoding
cat ./ca/ca.crt | base64
cat ./ca/ca.key | base64
```

### 2. Create a k8s secret to store the CA certificate

Run the `make create-ca-secret` found inside [self-signed-cert.mk](self-signed-cert.mk)

### 3. Create a custom CA issuer

Run the `make c8sm-issuer` found inside [self-signed-cert.mk](self-signed-cert.mk)

### 4. Create a custom self-signed certificate

Run the `make k8s-cert` found inside [self-signed-cert.mk](self-signed-cert.mk)

### 5. Configure your values.yaml file to enable tls encryption

See [camunda-values-tls-enabled.yaml](camunda-values-tls-enabled.yaml) as an example. 






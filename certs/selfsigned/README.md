# TLS Certificates and Camunda 8

This folder contains notes, suggestions, and guidance for provisioning and configuring TLS Certificates and Camunda 8

## Create a Custom Certificate Authority (CA)

I used the following commands to create a Certificate Authority.

```shell
# Create a public private key pair
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ca/ca.key -out ca/ca.crt -subj "/CN=c8sm/O=c8sm"
# Convert the keys to base64 encoding
cat ./ca/ca.crt | base64
cat ./ca/ca.key | base64
```

The password for the [myCa.key](selfsigned/ca/myCA.key) private key is `camunda`.

Then, I used the following commands to create a K8s secret containing the private key and certificate for my CA: 

```shell
cat ./ca/myCA.pem | base64 -b0
cat ./ca/myCA.key | base64 -b0
```

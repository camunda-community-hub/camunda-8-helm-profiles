# Create a cert to use with GRPC gateway
# this script uses dependencies (cfssl, cfssljosn, jq)
root ?= $(shell pwd)/..

namespace ?= camunda
# Service to apply cert
service ?= zeebe-gateway
# TLS secret name
secret_name ?= tls-secret
# Cert Signing Reqest (CSR) signer name
signerName ?= 127.0.0.1.nip.io\/pdiddy

.PHONY: all
all: cfssl-create-csr kube-upload-csr kube-approve-csr \
	 cfssl-create-cert-authority cfssl-sign-certificate \
	 kube-upload-cert kube-create-secret clean-certs

include $(root)/cfssl/cfssl-certs.mk

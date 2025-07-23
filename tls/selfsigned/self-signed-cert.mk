# Makefile for creating self-signed certificates

.PHONY: create-certs-dir
create-certs-dir:
	mkdir -p ./certs

.PHONY: delete-certs-dir
delete-certs-dir:
	rm -rf ./certs

# create CA private key
.PHONY: create-ca-private-key
create-ca-private-key: create-certs-dir delete-ca-private-key
	openssl genrsa -des3 -out ./certs/$(certName)CA.key 2048

.PHONY: delete-ca-private-key
delete-ca-private-key:
	rm -rf ./certs/$(certName)CA.key

# create CA certificate
.PHONY: create-ca-pem
create-ca-pem: create-certs-dir delete-ca-pem
	openssl req -x509 -new -nodes -key ./certs/$(certName)CA.key -sha256 -days 365 \
	  -out ./certs/$(certName)CA.pem \
	  -subj "/C=US/ST=Virginia/L=Fredericksburg/O=Camunda/OU=IT Department/CN=$(certName) CA" \

.PHONY: delete-ca-pem
delete-ca-pem:
	rm -rf ./certs/$(certName)CA.pem

# This will add the cert to the `Keychain Access`. Remember to make sure the cert is set to `Always Trust`
.PHONY: add-ca-cert-to-ios
add-ca-cert-to-ios:
	sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ./certs/$(certName)CA.pem

# Create a private key for the server based on custom CA
.PHONY: create-server-private-key
create-server-private-key: delete-server-private-key
	openssl genrsa -out ./certs/$(certName)Server.key 2048

.PNONY: delete-server-private-key
delete-server-private-key:
	rm -rf ./certs/$(certName)Server.key

.PHONY: create-certs-cnf
create-certs-cnf: create-certs-dir
	sed "s/RELEASE/$(release)/g; s/NAMESPACE/$(namespace)/g;" $(root)/tls/selfsigned/cert.tpl.cnf > ./certs/cert.cnf

.PHONY: create-san-ext
create-san-ext: create-certs-dir
	sed "s/RELEASE/$(release)/g; s/NAMESPACE/$(namespace)/g;" $(root)/tls/selfsigned/san.tpl.ext > ./certs/san.ext

# Create a CSR (Certificate Signing Request) for the server
.PHONY: create-server-csr
create-server-csr: create-certs-dir delete-server-csr create-certs-cnf
	openssl req -new -key ./certs/$(certName)Server.key -out ./certs/$(certName)Server.csr \
	-config ./certs/cert.cnf

.PHONY: delete-server-csr
delete-server-csr:
	rm -rf ./certs/$(certName)Server.csr

# Create a certificate for the server based on the CA
.PHONY: create-server-cert
create-server-cert: create-certs-dir delete-server-cert create-san-ext
	openssl x509 -req -in ./certs/$(certName)Server.csr -CA ./certs/$(certName)CA.pem \
	  -CAkey ./certs/$(certName)CA.key -CAcreateserial -out ./certs/$(certName)Server.crt \
	  -days 365 -sha256 -extfile ./certs/san.ext

.PHONY: delete-server-cert
delete-server-cert:
	rm -rf $(root)/tls/selfsigned/server/$(certName)Server.crt

.PHONY: create-custom-certs
create-custom-certs: create-ca-private-key create-ca-pem create-server-private-key create-server-csr create-server-cert

.PHONY: delete-custom-certs
delete-custom-certs: delete-certs-dir

.PHONY: list-sans
list-sans:
	openssl x509 -noout -ext subjectAltName -in ./certs/$(certName)Server.crt



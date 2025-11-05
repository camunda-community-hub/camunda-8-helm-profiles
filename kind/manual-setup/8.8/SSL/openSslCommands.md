
## Create new Root CA

### Generate Private Key for the CA
```
    openssl genrsa -out myCA.key 4096
```

### Create Self-Signed CA

```
    openssl req -x509 -new -nodes -key myCA.key -sha256 -days 1825 \
    -out myCA.crt \
    -subj "/C=DE/ST=Berlin/L=Berlin/O=My Local CA/CN=My Local CA Root"
```

## Create Server Certificate 

### Create Key
```
    openssl genrsa -out camunda-local-tls.key 2048
```

### Create CSR (Certificate Signing Request)
```
    openssl req -new -key camunda-local-tls.key -out camunda-local-tls.csr \
    -subj "/C=DE/ST=Berlin/L=Berlin/O=Camunda/CN=camunda.local"
```

### Create SAN-Configuration (Subject Alternative Name)
create file san.cnf

```
    subjectAltName = @alt_names
    [alt_names]
    DNS.1 = camunda.local
    DNS.2 = zeebe.camunda.local
```

### Sign Server Certificate with the new Root CA
```
    openssl x509 -req -in camunda-local-tls.csr \
    -CA myCA.crt -CAkey myCA.key -CAcreateserial \
    -out camunda-local-tls.crt -days 365 -sha256 \
    -extfile san.cnf
```

## Import the new Root CA into your System
### Macbook
1. open Keychain Access
2. Select System
3. File ==> Import Items ==> select the new Root CA file (myCA.crt)
4. Double click the newly imported CA and select Trust ==> Always Trust


### Windows
please add here

### Linux
please add here

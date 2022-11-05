# Camunda 8 Helm Profile: Ingress NGINX for AWS EKS

## TLS Certificates

dave@Davids-MBP tls % kubectl get certificaterequest --all-namespaces
NAMESPACE   NAME               APPROVED   DENIED   READY   ISSUER        REQUESTOR                                         AGE
camunda     tls-secret-ltx5k   True                False   letsencrypt   system:serviceaccount:cert-manager:cert-manager   32m

Need to work around this issue: 

Message:               Failed to wait for order resource "tls-secret-ltx5k-1407422140" to become ready: order is in "errored" state: Failed to create Order: 400 urn:ietf:params:acme:error:rejectedIdentifier: NewOrder request did not include a SAN short enough to fit in CN

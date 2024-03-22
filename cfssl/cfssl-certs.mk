# Create a cert to use with GRPC gateway
# this script uses cfssl, cfssljosn, jq

.PHONY: cfssl-create-csr
cfssl-create-csr:
	mkdir certs
	cat $(root)/cfssl/template/csr.json | cfssl genkey - | cfssljson -bare server -f
	mv server* ./certs/

.PHONY: kube-upload-csr
kube-upload-csr:
	sed "s/<SERVER-CSR-VALUE>/$(shell cat certs/server.csr | base64 | tr -d '\n')/g; \
		s/<SERVICE-NAMESPACE-VALUE>/$(service).$(namespace)/g; \
	 	s/<SIGNER-NAME>/$(signerName)/g;" \
		$(root)/cfssl/template/csr.tpl.yaml > ./certs/csr.yaml
	kubectl apply -f ./certs/csr.yaml -n $(namespace)
	kubectl describe csr $(service).$(namespace) -n $(namespace)

.PHONY: kube-approve-csr
kube-approve-csr:
	kubectl certificate approve $(service).$(namespace) -n $(namespace)
	kubectl get csr -n $(namespace)

.PHONY: cfssl-create-cert-authority
cfssl-create-cert-authority:
	cat $(root)/cfssl/template/ca.json | cfssl gencert -initca - | cfssljson -bare ca
	mv ca-* ./certs/
	mv ca.* ./certs/

.PHONY: cfssl-sign-certificate
cfssl-sign-certificate:
	kubectl get csr $(service).$(namespace) -o jsonpath='{.spec.request}' | \
  base64 --decode | \
  cfssl sign -ca ./certs/ca.pem -ca-key ./certs/ca-key.pem \
		-config $(root)/cfssl/template/server-signing-config.json - | \
  	cfssljson -bare ca-signed-server -n $(namespace)
	mv ca-* ./certs/

.PHONY: kube-upload-cert
kube-upload-cert:
	kubectl get csr $(service).$(namespace) -o json | \
  jq '.status.certificate = "'$(shell base64 -i ./certs/ca-signed-server.pem | tr -d '\n')'"' | \
  kubectl replace --raw /apis/certificates.k8s.io/v1/certificatesigningrequests/$(service).$(namespace)/status -f - -n $(namespace)
	kubectl get csr -n $(namespace)

.PHONY: kube-get-client-cert
kube-get-client-cert:
	$(shell kubectl get csr $(service).$(namespace) -n $(namespace) -o jsonpath='{.status.certificate}' \
    | base64 --decode > ./certs/signed-client.crt)

.PHONY: kube-create-client-cert
kube-create-client-cert:
	# kubectl get csr $(service).$(namespace) -n $(namespace) -o jsonpath='{.status.certificate}' \
  #   | base64 --decode |
	kubectl create secret generic zeebe-gateway-client-secret --from-file ./certs/signed-client.crt -n $(namespace)

.PHONY: kube-create-secret
kube-create-secret:
	-kubectl delete secret $(secretName)
	kubectl create secret tls $(secretName) --cert ./certs/ca-signed-server.pem --key ./certs/server-key.pem -n $(namespace)
	kubectl get secret $(secretName) -n $(namespace) -o json

.PHONY: clean-certs
clean-certs:
	-rm -Rf ./certs
	-kubectl delete csr $(service).$(namespace)

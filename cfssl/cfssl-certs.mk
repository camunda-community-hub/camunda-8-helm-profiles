# Create a cert to use with GRPC gateway
# this script uses cfssl, cfssljosn, jq

.PHONY: cfssl-create-csr
cfssl-create-csr:
	-mkdir certs
	-cat $(root)/cfssl/template/csr.json | cfssl genkey - | cfssljson -bare server -f
	-mv server* $(root)/cfssl/certs/ #TODO: update to use fully qualified paths?

.PHONY: kube-upload-csr
kube-upload-csr:
	sed "s/<SERVER-CSR-VALUE>/$(shell cat certs/server.csr | base64 | tr -d '\n')/g; \
		s/<SERVICE-NAMESPACE-VALUE>/$(service).$(namespace)/g; \
	 	s/<SIGNER-NAME>/$(signerName)/g;" \
		$(root)/cfssl/template/csr.tpl.yaml > $(root)/cfssl/csr.yaml
	kubectl apply -f $(root)/cfssl/csr.yaml -n $(namespace)
	kubectl describe csr $(service).$(namespace) -n $(namespace)

.PHONY: kube-approve-csr
kube-approve-csr:
	kubectl certificate approve $(service).$(namespace) -n $(namespace)
	kubectl get csr -n $(namespace)

.PHONY: cfssl-create-cert-authority
cfssl-create-cert-authority:
	cat $(root)/cfssl/template/ca.json | cfssl gencert -initca - | cfssljson -bare ca
	mv ca* $(root)/cfssl/certs/ #TODO: update to use fully qualified paths?

.PHONY: cfssl-sign-certificate
cfssl-sign-certificate:
	kubectl get csr $(service).$(namespace) -o jsonpath='{.spec.request}' | \
  base64 --decode | \
  cfssl sign -ca $(root)/cfssl/certs/ca.pem -ca-key $(root)/cfssl/certs/ca-key.pem \
		-config $(root)/certs/template/server-signing-config.json - | \
  	cfssljson -bare ca-signed-server -n $(namespace)
	mv ca* $(root)/cfssl/certs/ # TODO: update to use fully qualified paths

.PHONY: kube-upload-cert
kube-upload-cert:
	kubectl get csr $(service).$(namespace) -o json | \
  jq '.status.certificate = "'$(shell base64 $(root)/cfssl/certs/ca-signed-server.pem | tr -d '\n')'"' | \
  kubectl replace --raw /apis/certificates.k8s.io/v1/certificatesigningrequests/$(service).$(namespace)/status -f - -n $(namespace)
	kubectl get csr -n $(namespace)

.PHONY: kube-create-secret
kube-create-secret:
	-kubectl delete secret $(secret_name)
	$(shell kubectl get csr $(service).$(namespace) -n $(namespace) -o jsonpath='{.status.certificate}' \
    | base64 --decode > ./signed-server.crt)
	kubectl create secret tls $(secret_name) --cert $(root)/cfssl/certs/signed-server.crt --key $(root)/cfssl/certs/server-key.pem -n $(namespace)
	kubectl get secret $(secret_name) -n $(namespace) -o json

.PHONY: clean-certs
clean-certs:
	rm -Rf $(root)/cfssl/certs
	kubectl delete csr $(service).$(namespace)

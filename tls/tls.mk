.PHONY: create-tls-secret
create-tls-secret:
	kubectl create secret tls $(certName)-tls-secret --cert=./certs/$(certName)Server.crt --key=./certs/$(certName)Server.key -n $(namespace)

.PHONY: delete-tls-secret
delete-tls-secret:
	kubectl delete secret $(certName)-tls-secret -n $(namespace)

.PHONY: create-ca-secret
create-ca-secret:
	kubectl create secret generic $(certName)-ca-secret --from-file=./certs/$(certName)CA.pem -n $(namespace)

.PHONY: delete-ca-secret
delete-ca-secret:
	kubectl delete secret $(certName)-ca-secret

.PHONY: netshoot
netshoot:
	kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -n $(namespace)

#docker run --rm -it --entrypoint /bin/sh upgradingdave/zbctl-java:main

zbctl-plaintext-job.yaml:
	sed "s/RELEASE/$(release)/g; s/CLIENT_SECRET/$(clientSecret)/g;" $(root)/tls/zbctl-plaintext-job.tpl.yaml > ./zbctl-plaintext-job.yaml

.PHONY: create-zbctl-plaintext-job
create-zbctl-plaintext-job: namespace zbctl-plaintext-job.yaml
	kubectl apply -f ./zbctl-plaintext-job.yaml -n $(namespace)

zbctl-tls-job.yaml:
	sed "s/CERT_NAME/$(certName)/g; s/RELEASE/$(release)/g; s/CLIENT_SECRET/$(clientSecret)/g;" $(root)/tls/zbctl-tls-job.tpl.yaml > ./zbctl-tls-job.yaml

.PHONY: create-zbctl-tls-job
create-zbctl-tls-job: namespace zbctl-tls-job.yaml
	kubectl apply -f ./zbctl-tls-job.yaml -n $(namespace)

#kubectl logs jobs/zbctl-plaintext -f -n $(namespace)

.PHONY: delete-zbctl-plaintext-job
delete-zbctl-jobs:
	-kubectl delete -f ./zbctl-plaintext-job.yaml -n $(namespace)
	-kubectl delete -f ./zbctl-tls-job.yaml -n $(namespace)
	-rm -rf ./zbctl-plaintext-job.yaml
	-rm -rf ./zbctl-tls-job.yaml

#
#$ echo | \
#    openssl s_client -servername www.example.com -connect www.example.com:443 2>/dev/null | \
#    openssl x509 -text


.PHONY: create-keystore
create-keystore: delete-keystore
	openssl pkcs12 -export -in ./certs/$(certName)Server.crt -inkey ./certs/$(certName)Server.key \
               -out ./certs/$(certName)Server.p12 -name $(certName)-p12 \
               -CAfile ./certs/$(certName)CA.pem -caname $(certName)-ca
	keytool -importkeystore -deststorepass camunda -destkeypass camunda -destkeystore ./certs/keystore.jks -srckeystore ./certs/$(certName)Server.p12 -srcstoretype PKCS12 -srcstorepass camunda

.PHONY: delete-keystore
delete-keystore:
	rm -rf ./certs/keystore.jks
	rm -rf ./certs/$(certName)Server.p12

.PHONY: list-keystore
list-keystore:
	keytool -list -v -keystore ./certs/keystore.jks -storepass camunda

.PHONY: create-truststore
create-truststore: delete-truststore
	keytool -import -keystore ./certs/truststore.jks -storepass camunda -noprompt -file ./certs/$(certName)CA.pem -alias $(certName)-ca-cert

.PHONY: delete-truststore
delete-truststore:
	rm -rf ./certs/truststore.jks

.PHONY: list-truststore
list-truststore:
	keytool -list -v -keystore ./certs/truststore.jks -storepass camunda

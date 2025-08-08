camunda-credentials.yaml:
	$(eval base64Password := $(shell echo $(defaultPassword) | base64))
	sed "s/<CHANGE_PASSWORD>/$(base64Password)/g;" $(root)/secrets/camunda-credentials.tpl.yaml > ./camunda-credentials.yaml

.PHONY: camunda-credentials
camunda-credentials: namespace camunda-credentials.yaml
	kubectl apply -f ./camunda-credentials.yaml -n $(namespace)

.PHONY: clean-camunda-credentials
clean-camunda-credentials:
	-kubectl delete -f ./camunda-credentials.yaml -n $(namespace)
	-rm -f ./camunda-credentials.yaml
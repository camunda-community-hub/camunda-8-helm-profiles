
.PHONY: actuator-application-yaml
actuator-application-yaml: namespace
	kubectl create configmap additional-application-yaml --from-file=$(root)/spring-actuator/application.yaml -n $(namespace)


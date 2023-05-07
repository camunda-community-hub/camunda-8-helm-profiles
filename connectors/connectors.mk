
# SendGrid

.PHONY: set-sendgrid-secret
set-sendgrid-secret:
	$(eval SECRET := $(shell bash -c 'read -p "SENGRDI_KEY: " secret; echo $$secret'))
	kubectl set env deployment camunda-connectors SENDGRID_KEY=$(SECRET) CAMUNDA_OPERATE_CLIENT_USERNAME=demo CAMUNDA_OPERATE_CLIENT_PASSWORD=demo

.PHONY: set-openai-secret
set-openai-secret:
	$(eval SECRET := $(shell bash -c 'read -p "OPENAI_KEY: " secret; echo $$secret'))
	kubectl set env deployment camunda-connectors OPENAI_KEY=$(SECRET)


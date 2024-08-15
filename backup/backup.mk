.PHONY: create-aws-credentials-secret
create-aws-credentials-secret:
	-kubectl create secret generic "aws-credentials"  \
	--from-literal=key=$(awsKey) \
	--from-literal=secret=$(awsSecret)



.PHONY: create-vpc
create-vpc:
	aws ec2 create-vpc \
      --cidr-block $(CIDR_BLOCK) \
      --region $(REGION) \
      --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=$(VPC_NAME)}]'

.PHONY: create-vpc-01
create-vpc-01:
	$(MAKE) -C $(root)/aws/vpc create-vpc VPC_NAME=$(DEPLOYMENT_NAME)-vpc-01 REGION=$(REGION) CIDR_BLOCK=$(CIDR_BLOCK)

.PHONY: create-vpc-02
create-vpc-02:
	$(MAKE) -C $(root)/aws/vpc create-vpc VPC_NAME=$(DEPLOYMENT_NAME)-vpc-02 REGION=$(REGION) CIDR_BLOCK=$(CIDR_BLOCK)

.PHONY: delete-vpc
delete-vpc:
	$(eval VPC_ID := $(shell aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$(VPC_NAME)" --query "Vpcs[0].VpcId" --output text))
	aws ec2 delete-vpc --vpc-id $(VPC_ID)
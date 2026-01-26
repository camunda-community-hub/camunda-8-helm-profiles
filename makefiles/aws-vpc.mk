.PHONY: create-vpc
create-vpc:
	aws ec2 create-vpc \
      --cidr-block $(CIDR_BLOCK) \
      --region $(REGION) \
      --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=$(VPC_NAME)}]'

.PHONY: delete-vpc
delete-vpc:
	$(eval VPC_ID := $(shell aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$(VPC_NAME)" --query "Vpcs[0].VpcId" --output text))
	aws ec2 delete-vpc --vpc-id $(VPC_ID)

.PHONY: create-subnet
create-subnet:
	$(eval VPC_ID := $(shell aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$(VPC_NAME)" --query "Vpcs[0].VpcId" --output text))
	aws ec2 create-subnet \
	  --vpc-id $(VPC_ID) \
	  --cidr-block $(SUBNET_CIDR_BLOCK) \
	  --availability-zone $(AVAILABILITY_ZONE) \
	  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=$(SUBNET_NAME)}]'

.PHONY: delete-subnet
delete-subnet:
	$(eval SUBNET_ID := $(shell aws ec2 describe-subnets --filters "Name=tag:Name,Values=$(SUBNET_NAME)" --query "Subnets[0].SubnetId" --output text))
	aws ec2 delete-subnet --subnet-id $(SUBNET_ID)
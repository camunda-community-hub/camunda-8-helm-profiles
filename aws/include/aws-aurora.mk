.PHONY: get-eks-subnets
get-eks-subnets:
	aws eks describe-cluster --name $(CLUSTER) --region $(REGION) \
	  --query 'cluster.resourcesVpcConfig.subnetIds' --output text

.PHONY: create-db-subnet-group-from-eks
create-db-subnet-group-from-eks:
	$(eval SUBNETS := $(shell aws eks describe-cluster --name $(DEPLOYMENT_NAME) --region $(REGION) \
	  --query 'cluster.resourcesVpcConfig.subnetIds' --output text))
#	$(eval VPC_ID := $(shell aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$(VPC_NAME)" --query "Vpcs[0].VpcId" --output text))
#	$(eval SUBNETS := $(shell aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(VPC_ID)" --query "Subnets[*].SubnetId" --output text))
	aws rds create-db-subnet-group \
		--db-subnet-group-name $(DEPLOYMENT_NAME)-aurora-group \
		--db-subnet-group-description "Subnet Aurora db group for $(DEPLOYMENT_NAME)" \
		--subnet-ids $(SUBNETS)

.PHONY: create-db
create-db:
	aws rds create-db-cluster \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--engine aurora-postgresql \
		--master-username $(POSTGRES_MASTER_USERNAME) \
		--master-user-password $(POSTGRES_MASTER_PASSWORD) \
		--db-subnet-group-name $(DEPLOYMENT_NAME)-aurora-group

	@echo "Waiting for cluster to initialize..."
	aws rds wait db-cluster-available --db-cluster-identifier $(DEPLOYMENT_NAME)-cluster

	@echo "Creating Instance..."
	aws rds create-db-instance \
		--db-instance-identifier $(DEPLOYMENT_NAME)-instance \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--engine aurora-postgresql \
		--db-instance-class db.t3.medium \
		--publicly-accessible

# Usage: make get-db-url NAME=my-aurora
get-db-url:
	$(eval ENDPOINT := $(shell aws rds describe-db-clusters --db-cluster-identifier $(NAME)-cluster --query "DBClusters[0].Endpoint" --output text))
	@echo "PostgreSQL Connection String:"
	@echo "postgresql://dbadmin:YourPassword@$(ENDPOINT):5432/postgres"

# 1. Get the Security Group ID of your RDS cluster
#RDS_SG=$(aws rds describe-db-clusters --db-cluster-identifier my-cluster --query "DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId" --output text)

# 2. Get the Security Group ID of your EKS Nodes
#EKS_SG=$(aws eks describe-cluster --name my-eks-cluster --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)

# 3. Authorize traffic from EKS to RDS
#aws ec2 authorize-security-group-ingress \
#    --group-id $RDS_SG \
#    --protocol tcp \
#    --port 5432 \
#    --source-group $EKS_SG

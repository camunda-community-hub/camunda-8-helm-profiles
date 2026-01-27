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
		--subnet-ids $(SUBNETS) \
		--no-cli-pager

.PHONY: create-aurora-db-secret
create-aurora-db-secret: delete-aurora-db-secret
	@echo "Creating secret in AWS Secrets Manager..."
	aws secretsmanager create-secret \
		--name $(DEPLOYMENT_NAME)-db-secret \
		--description "Admin credentials for $(DEPLOYMENT_NAME) Aurora cluster" \
		--secret-string '{"username":"$(POSTGRES_MASTER_USERNAME)","password":"$(POSTGRES_MASTER_PASSWORD)"}' \
		--no-cli-pager

.PHONY: delete-aurora-db-secret
delete-aurora-db-secret:
	@echo "Deleting secret: $(DEPLOYMENT_NAME)-db-secret..."
	-aws secretsmanager delete-secret \
		--secret-id $(DEPLOYMENT_NAME)-db-secret \
		--force-delete-without-recovery \
		--no-cli-pager
	@echo "Secret scheduled for immediate deletion."

.PHONY: create-aurora-db
create-aurora-db: create-db-subnet-group-from-eks
	aws rds create-db-cluster \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--engine aurora-postgresql \
		--master-username $(POSTGRES_MASTER_USERNAME) \
		--master-user-password $(POSTGRES_MASTER_PASSWORD) \
		--db-subnet-group-name $(DEPLOYMENT_NAME)-aurora-group \
		--no-cli-pager

	@echo "Waiting for cluster to initialize..."
	aws rds wait db-cluster-available --db-cluster-identifier $(DEPLOYMENT_NAME)-cluster

	@echo "Creating Instance..."
	aws rds create-db-instance \
		--db-instance-identifier $(DEPLOYMENT_NAME)-instance \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--engine aurora-postgresql \
		--db-instance-class db.t3.medium \
		--publicly-accessible \
		--no-cli-pager

	@echo "Waiting for instance $(DEPLOYMENT_NAME)-instance to reach 'Available' state..."
	aws rds wait db-instance-available \
		--db-instance-identifier $(DEPLOYMENT_NAME)-instance \
		--no-cli-pager
	@echo "Instance is ready for connections."

.PHONY: _setup-db
_setup-db:
	@echo "Fetching master password and endpoint..."
	$(eval DB_HOST := $(shell aws rds describe-db-clusters \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--query "DBClusters[0].Endpoint" --output text))

	@echo "Connecting to $(DB_HOST) to provision $(DB_NAME) database and user..."
	@export PGPASSWORD=$(POSTGRES_MASTER_PASSWORD); \
	psql -h $(DB_HOST) -U $(POSTGRES_MASTER_USERNAME) -d postgres \
		-c "CREATE DATABASE $(DB_NAME);" \
		-c "CREATE USER $(DB_USER) WITH PASSWORD '$(DEFAULT_PASSWORD)';" \
		-c "GRANT ALL PRIVILEGES ON DATABASE $(DB_NAME) TO $(DB_USER);"

	@echo "Configuring schema permissions on $(DB_NAME)..."
	@export PGPASSWORD=$(POSTGRES_MASTER_PASSWORD); \
	psql -h $(DB_HOST) -U $(POSTGRES_MASTER_USERNAME) -d $(DB_NAME) \
		-c "GRANT ALL ON SCHEMA public TO $(DB_USER);" \
		-c "ALTER SCHEMA public OWNER TO $(DB_USER);" \
		-c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $(DB_USER);"

	@echo "--------------------------------------------------"
	@echo "$(DB_LABEL) Database and User created successfully."
	@echo "Database: $(DB_NAME)"
	@echo "User: $(DB_USER)"
	@echo "--------------------------------------------------"

.PHONY: _cleanup-db
_cleanup-db:
	@echo "Fetching master password and endpoint..."
	$(eval DB_HOST := $(shell aws rds describe-db-clusters \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--query "DBClusters[0].Endpoint" --output text))

	@echo "Terminating active connections and dropping $(DB_NAME)..."
	@export PGPASSWORD=$(POSTGRES_MASTER_PASSWORD); \
	psql -h $(DB_HOST) -U $(POSTGRES_MASTER_USERNAME) -d postgres \
		-c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$(DB_NAME)' AND pid <> pg_backend_pid();" \
		-c "DROP DATABASE IF EXISTS $(DB_NAME);" \
		-c "DROP USER IF EXISTS $(DB_USER);"

	@echo "--------------------------------------------------"
	@echo "$(DB_LABEL) Database and User removed."
	@echo "--------------------------------------------------"

.PHONY: setup-modeler-db
setup-modeler-db: DB_NAME := $(POSTGRES_MODELER_DB)
setup-modeler-db: DB_USER := $(POSTGRES_MODELER_USERNAME)
setup-modeler-db: DB_LABEL := Modeler
setup-modeler-db: _setup-db

.PHONY: setup-keycloak-db
setup-keycloak-db: DB_NAME := $(POSTGRES_KEYCLOAK_DB)
setup-keycloak-db: DB_USER := $(POSTGRES_KEYCLOAK_USERNAME)
setup-keycloak-db: DB_LABEL := Keycloak
setup-keycloak-db: _setup-db

.PHONY: setup-identity-db
setup-identity-db: DB_NAME := $(POSTGRES_IDENTITY_DB)
setup-identity-db: DB_USER := $(POSTGRES_IDENTITY_USERNAME)
setup-identity-db: DB_LABEL := Identity
setup-identity-db: _setup-db

.PHONY: setup-all-dbs
setup-all-dbs: setup-modeler-db setup-keycloak-db setup-identity-db

.PHONY : cleanup-modeler-db
cleanup-modeler-db: DB_NAME := $(POSTGRES_MODELER_DB)
cleanup-modeler-db: DB_USER := $(POSTGRES_MODELER_USERNAME)
cleanup-modeler-db: DB_LABEL := Modeler
cleanup-modeler-db: _cleanup-db

.PHONY : cleanup-keycloak-db
cleanup-keycloak-db: DB_NAME := $(POSTGRES_KEYCLOAK_DB)
cleanup-keycloak-db: DB_USER := $(POSTGRES_KEYCLOAK_USERNAME)
cleanup-keycloak-db: DB_LABEL := Keycloak
cleanup-keycloak-db: _cleanup-db

.PHONY : cleanup-identity-db
cleanup-identity-db: DB_NAME := $(POSTGRES_IDENTITY_DB)
cleanup-identity-db: DB_USER := $(POSTGRES_IDENTITY_USERNAME)
cleanup-identity-db: DB_LABEL := Identity
cleanup-identity-db: _cleanup-db

.PHONY: cleanup-all-dbs
cleanup-all-dbs: cleanup-modeler-db cleanup-keycloak-db cleanup-identity-db

.PHONY: destroy-aurora-db
destroy-aurora-db: revoke-local-to-rds revoke-eks-to-rds delete-aurora-db-secret
	@echo "Deleting RDS Instance: $(DEPLOYMENT_NAME)-instance..."
	-aws rds delete-db-instance \
		--db-instance-identifier $(DEPLOYMENT_NAME)-instance \
		--skip-final-snapshot \
		--no-cli-pager

	@echo "Waiting for instance to be deleted (this may take a few minutes)..."
	@aws rds wait db-instance-deleted --db-instance-identifier $(DEPLOYMENT_NAME)-instance

	@echo "Deleting RDS Cluster: $(DEPLOYMENT_NAME)-cluster..."
	-aws rds delete-db-cluster \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--skip-final-snapshot \
		--no-cli-pager

	@echo "Waiting for cluster to be deleted..."
	@# Note: There is no 'wait db-cluster-deleted' in some CLI versions,
	@# so we loop until the describe command fails or returns nothing.
	@while aws rds describe-db-clusters --db-cluster-identifier $(DEPLOYMENT_NAME)-cluster >/dev/null 2>&1; do \
		sleep 10; \
		echo "Still deleting cluster..."; \
	done

	@echo "Deleting DB Subnet Group: $(DEPLOYMENT_NAME)-subnet-group..."
	-aws rds delete-db-subnet-group --db-subnet-group-name $(DEPLOYMENT_NAME)-aurora-group --no-cli-pager
	@echo "Database infrastructure for $(DEPLOYMENT_NAME) destroyed successfully."

.PHONY: allow-local-to-rds
allow-local-to-rds:
	@echo "Detecting public IP..."
	$(eval MY_IP := $(shell curl -s https://checkip.amazonaws.com))
	@echo "Your Public IP is: $(MY_IP)"

	@echo "Looking up Security Group for $(DEPLOYMENT_NAME)-cluster..."
	$(eval SG_ID := $(shell aws rds describe-db-clusters \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--query "DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
		--no-cli-pager --output text))

	@echo "Opening port 5432 for $(MY_IP)/32 on Security Group $(SG_ID)..."
	@aws ec2 authorize-security-group-ingress \
		--group-id $(SG_ID) \
		--protocol tcp \
		--port 5432 \
		--cidr $(MY_IP)/32 \
		--no-cli-pager || echo "Access already open or rule exists."

.PHONY: revoke-local-to-rds
revoke-local-to-rds:
	$(eval MY_IP := $(shell curl -s https://checkip.amazonaws.com))
	$(eval SG_ID := $(shell aws rds describe-db-clusters \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--query "DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
		--no-cli-pager --output text))
	@echo "Revoking access for $(MY_IP)..."
	-@aws ec2 revoke-security-group-ingress \
		--group-id $(SG_ID) \
		--protocol tcp \
		--port 5432 \
		--cidr $(MY_IP)/32 \
		--no-cli-pager

# Usage: make allow-eks-to-rds DEPLOYMENT_NAME=<name>
.PHONY: allow-eks-to-rds
allow-eks-to-rds:
	@echo "Discovering Security Group IDs..."
	$(eval RDS_SG := $(shell aws rds describe-db-clusters \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--query "DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
		--no-cli-pager --output text))

	$(eval EKS_SG := $(shell aws eks describe-cluster \
		--name $(DEPLOYMENT_NAME) \
		--query "cluster.resourcesVpcConfig.clusterSecurityGroupId" \
		--no-cli-pager --output text))

	@echo "RDS Security Group: $(RDS_SG)"
	@echo "EKS Node Security Group: $(EKS_SG)"

	@echo "Authorizing TCP port 5432 ingress from EKS to RDS..."
	aws ec2 authorize-security-group-ingress \
		--group-id $(RDS_SG) \
		--protocol tcp \
		--port 5432 \
		--source-group $(EKS_SG) \
		--no-cli-pager || echo "Rule might already exist, skipping..."

.PHONY: revoke-eks-to-rds
revoke-eks-to-rds:
	@echo "Discovering Security Group IDs for cleanup..."
	$(eval RDS_SG := $(shell aws rds describe-db-clusters \
		--db-cluster-identifier $(DEPLOYMENT_NAME)-cluster \
		--query "DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
		--no-cli-pager --output text))

	$(eval EKS_SG := $(shell aws eks describe-cluster \
		--name $(DEPLOYMENT_NAME) \
		--query "cluster.resourcesVpcConfig.clusterSecurityGroupId" \
		--no-cli-pager --output text))

	@echo "RDS Security Group: $(RDS_SG)"
	@echo "EKS Node Security Group: $(EKS_SG)"

	@echo "Revoking TCP port 5432 ingress from EKS to RDS..."
	@aws ec2 revoke-security-group-ingress \
		--group-id $(RDS_SG) \
		--protocol tcp \
		--port 5432 \
		--source-group $(EKS_SG) \
		--no-cli-pager || echo "Rule not found or already removed, skipping..."

.PHONY: set-postgres-host
set-postgres-host:
	$(eval POSTGRES_HOST := $(shell aws rds describe-db-clusters --db-cluster-identifier $(DEPLOYMENT_NAME)-cluster --query "DBClusters[0].Endpoint" --output text 2>/dev/null))

.PHONY: test-aurora-from-local
test-aurora-from-local:
	$(eval DB_HOST := $(shell aws rds describe-db-clusters --db-cluster-identifier $(DEPLOYMENT_NAME)-cluster --query "DBClusters[0].Endpoint" --output text))
	@PGPASSWORD='$(POSTGRES_MASTER_PASSWORD)' psql -h $(DB_HOST) -U $(POSTGRES_MASTER_USERNAME) -d postgres -c "SELECT version();"

# Usage: make get-db-url DEPLOIYMENT_NAME=my-aurora
.PHONY: get-aurora-connection-string
get-aurora-connection-string:
	$(eval ENDPOINT := $(shell aws rds describe-db-clusters --db-cluster-identifier $(DEPLOYMENT_NAME)-cluster --query "DBClusters[0].Endpoint" --output text))
	@echo "PostgreSQL Connection String:"
	@echo "postgresql://$(POSTGRES_MASTER_USERNAME):$(POSTGRES_MASTER_PASSWORD)@$(ENDPOINT):5432/postgres"

# Usage: make test-db-link RDS_ENDPOINT=xyz.cluster-123.us-east-1.rds.amazonaws.com
.PHONY: test-aurora-from-eks
test-aurora-from-eks:
	$(eval ENDPOINT := $(shell aws rds describe-db-clusters --db-cluster-identifier $(DEPLOYMENT_NAME)-cluster --query "DBClusters[0].Endpoint" --output text))
	@echo "Testing connectivity to $(ENDPOINT)..."
	kubectl run db-ping-test --rm -it --image=busybox --restart=Never -- \
		nc -zv -w 5 $(ENDPOINT) 5432
.PHONY: check-az
check-az:
	@echo "Checking Azure CLI configuration..."

	@# 1. Check if az is installed
	@if [ -z "$(shell command -v az 2> /dev/null)" ]; then \
		echo "Error: Azure CLI (az) is not installed. Visit https://aka.ms/installazureclideb"; \
		exit 1; \
	fi

	@# 2. Check if logged in
	@if ! az account show > /dev/null 2>&1; then \
		echo "Error: Not logged into Azure. Run 'az login'."; \
		exit 1; \
	fi

	@# 3. Verify an active subscription is set
	@SUBSCRIPTION=$$(az account show --query "name" -o tsv 2>/dev/null); \
	if [ -z "$$SUBSCRIPTION" ]; then \
		echo "Error: No active subscription found."; \
		exit 1; \
	fi

	@echo "✅ Azure CLI is installed and connected to: $$(az account show --query 'name' -o tsv)"
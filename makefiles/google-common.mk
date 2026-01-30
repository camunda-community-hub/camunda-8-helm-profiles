.PHONY: check-gcloud
check-gcloud:
	@echo "Checking gcloud configuration..."

	@# 1. Check if gcloud is installed
	@if [ -z "$(shell command -v gcloud 2> /dev/null)" ]; then \
		echo "Error: gcloud CLI is not installed. Please install it first."; \
		exit 1; \
	fi

	@# 2. Check if an account is authenticated
	@if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then \
		echo "Error: No active gcloud account found. Run 'gcloud auth login'."; \
		exit 1; \
	fi

	@# 3. Check if a project is set
	@if [ -z "$$(gcloud config get-value project 2>/dev/null)" ]; then \
		echo "Error: No Google Cloud project set. Run 'gcloud config set project [PROJECT_ID]'."; \
		exit 1; \
	fi

	@echo "✅ gcloud is installed and configured: $$(gcloud config get-value project)"

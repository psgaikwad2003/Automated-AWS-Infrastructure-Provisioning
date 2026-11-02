.PHONY: init plan apply destroy lint format validate clean help ansible-ping ansible-deploy

ENVIRONMENT ?= dev
TF_DIR = terraform/environments/$(ENVIRONMENT)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	cd $(TF_DIR) && terraform init

validate: ## Validate Terraform configuration
	cd $(TF_DIR) && terraform validate

format: ## Format Terraform code
	terraform fmt -recursive terraform/

lint: ## Run tflint
	tflint --recursive terraform/

plan: ## Run Terraform plan
	cd $(TF_DIR) && terraform plan -var-file=terraform.tfvars -out=tfplan

apply: ## Apply Terraform changes
	cd $(TF_DIR) && terraform apply tfplan

destroy: ## Destroy infrastructure
	cd $(TF_DIR) && terraform destroy -var-file=terraform.tfvars -auto-approve

ansible-ping: ## Test Ansible connectivity
	cd ansible && ansible all -m ping -i inventory/aws_ec2.yml

ansible-deploy: ## Run full Ansible deployment
	cd ansible && ansible-playbook playbooks/site.yml -i inventory/aws_ec2.yml

clean: ## Clean temporary files
	find . -name "*.tfplan" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true


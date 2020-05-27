THISDIR := $(notdir $(CURDIR))
PROJECT := $(THISDIR)
IP := 192.168.122.32

################################################################################
# util-makefile
####

SHELL := /bin/bash
DIR := $(shell echo $(shell cd "$(shell  dirname "${BASH_SOURCE[0]}" )" && pwd ))

# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Show Makefile help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
.PHONY: help

####
# util-makefile
################################################################################

.DEFAULT_GOAL := help

fmt:  ## Format all 'tf' files
	terraform fmt ./

validate:  ## Validate the configuration files in a directory.
	terraform validate ./
.PHONY: validate
lint: validate
.PHONY: lint

plan:  ## Generates an execution plan for Terraform.
	terraform plan -var-file=$(PROJECT).tfvars ./

apply:
	terraform apply -auto-approve -var-file=$(PROJECT).tfvars

init:
	terraform init

rebuild: destroy apply ## recreate terraform resources

destroy:
	terraform destroy -auto-approve

ssh: ## ssh into VM, unique after each rebuild so refresh known_hosts
	ssh-keygen -f ~/.ssh/known_hosts -R $(IP)
	ssh-keyscan "$(IP)" >> ~/.ssh/known_hosts
	ssh ubuntu@$(IP) -i id_rsa

create-keypair: ## create public/private keypair for ssh
	@echo "THISDIR=$(THISDIR)"
	ssh-keygen -t rsa -b 4096 -f id_rsa -C $(PROJECT) -N "" -q

metadata:
	terraform refresh && terraform output

validate-cloud-config: ## validate syntax of cloud_init
	cloud-init devel schema --config-file cloud_init.cfg

CURRENTTAG:=$(shell git describe --tags --abbrev=0)
NEWTAG ?= $(shell bash -c 'read -p "Please provide a new tag (currnet tag - ${CURRENTTAG}): " newtag; echo $$newtag')

OS ?= $(shell uname -s | tr A-Z a-z)

.DEFAULT_GOAL := help

AZ_SUBSCRIPTION := d57e7e81-e648-45d6-83cc-b304be945e86
AZ_LOCATION := westus
AZ_FA_RES_GROUP_NAME := azurefa1-rg
AZ_FA_STORAGE_ACCT_NAME := azurefa1storageacc
AZ_FA_NAME := ak-azurefa1

TF_RESOURCE_GROUP_NAME := tfstate-rg
TF_STORAGE_ACCOUNT_NAME := tfstate$(shell bash -c 'echo $$RANDOM')
TF_CONTAINER_NAME := tfstate

#help: @ List available tasks
help:
	@clear
	@echo "Usage: make COMMAND"
	@echo "Commands :"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-32s\033[0m - %s\n", $$1, $$2}'

#clean: @ Cleanup
clean:
	@rm -rf node_modules/ dist/

#install: @ Install NodeJS dependencies
install:
	pnpm install

#build: @ Build
build: install
	pnpm rb

#run: @ Run
run: build
	@pnpm start

#upgrade: @ Upgrade dependencies
upgrade:
	pnpm upgrade

#release: @ Create and push a new tag
release:
	$(eval NT=$(NEWTAG))
	@echo -n "Are you sure to create and push ${NT} tag? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo ${NT} > ./version.txt
	@git add -A
	@git commit -a -s -m "Cut ${NT} release"
	@git tag ${NT}
	@git push origin ${NT}
	@git push
	@echo "Done."

#version: @ Print current version(tag)
version:
	@echo $(shell git describe --tags --abbrev=0)

#create-resources: @ Create AZ resources
create-resources:
	az account list-locations -o table
	az vm list-usage --location $(AZ_LOCATION) --output table
	az login
	az account set --subscription $(AZ_SUBSCRIPTION)
	az group create --name $(AZ_FA_RES_GROUP_NAME) --location $(AZ_LOCATION)
	az storage account create --name $(AZ_FA_STORAGE_ACCT_NAME) --location $(AZ_LOCATION) --resource-group $(AZ_FA_RES_GROUP_NAME) --sku Standard_LRS --allow-blob-public-access false

#create-function: @ Create AZ function
create-function:
	az functionapp create --resource-group $(AZ_FA_RES_GROUP_NAME) --consumption-plan-location $(AZ_LOCATION) --runtime node --runtime-version 20 --functions-version 4 --name $(AZ_FA_NAME) --storage-account $(AZ_FA_STORAGE_ACCT_NAME)

#publish-function: @ Publish function
publish-function:
	func azure functionapp publish $(AZ_FA_NAME)

#delete-resources: @ Delete AZ resources
delete-resources:
	az functionapp delete --name $(AZ_FA_NAME) --resource-group $(AZ_FA_RES_GROUP_NAME)
	az storage account delete --name $(AZ_FA_STORAGE_ACCT_NAME)
	az group delete --name $(AZ_FA_RES_GROUP_NAME)

#tf-create-remote-storage-account: @ Configure remote state storage account
tf-create-remote-storage-account:
	# Create resource group
	az group create --name $(TF_RESOURCE_GROUP_NAME) --location $(AZ_LOCATION)

	# Create storage account
	az storage account create --resource-group $(TF_RESOURCE_GROUP_NAME) --name $(TF_STORAGE_ACCOUNT_NAME) --sku Standard_LRS --encryption-services blob

	# Create blob container
	az storage container create --name $(TF_CONTAINER_NAME) --account-name $(TF_STORAGE_ACCOUNT_NAME)
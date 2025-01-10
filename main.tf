terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "tfstate-rg"
      storage_account_name = "tfstate29056"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }

}

provider "azurerm" {
  features {}
  # Replace with your Azure subscription ID
  subscription_id = "d57e7e81-e648-45d6-83cc-b304be945e86"
  # Optional: Choose the desired Azure environment from [AzureCloud, AzureChinaCloud, AzureUSGovernment, AzureGermanCloud]
  # environment = "AzureCloud"
  # Optional: Set the Azure tenant ID if using Azure Active Directory (AAD) service principal authentication
  # tenant_id = "<your_tenant_id>"
  # Optional: Set the client ID of your AAD service principal
  # client_id = "<your_client_id>"
  # Optional: Set the client secret of your AAD service principal
  # client_secret = "<your_client_secret>"
}

locals {
 location  = "westus"
 tags = {
   Name = "Azure Functions"
   Env  = "Dev"
 }

}

resource "azurerm_resource_group" "af_group" {
  name     = "azurefa1-rg"
  location = local.location
  tags = {
    environment = "Azure Functions Resource Group"
  }
}
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
  subscription_id = "d57e7e81-e648-45d6-83cc-b304be945e86"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
 location = "eastus"
 rg_name = "azurefa1-rg"
 storage_account_name ="azurefa1storageacc"
 fa_name = "ak-azurefa1"
 fa_service_plan_name = "ak-azurefa1-service-plan"
 
 tags = {
   Name = "Azure Functions"
   Env  = "Dev"
 }

}

resource "azurerm_resource_group" "fa_rg" {
  name     = local.rg_name
  location = local.location
  tags = {
    environment = "Azure Functions Resource Group"
  }
}

resource "azurerm_storage_account" "fa_storage_account" {
  name = local.storage_account_name
  location = azurerm_resource_group.fa_rg.location
  resource_group_name = azurerm_resource_group.fa_rg.name
  account_tier = "Standard"
  account_replication_type = "LRS"
  min_tls_version = "TLS1_2"
  access_tier = "Hot"
  tags = local.tags
  timeouts {
    create = "3m"
    update = "3m"
    delete = "3m"
  }
}

resource "azurerm_service_plan" "fa_serviceplan" {
  name = local.fa_service_plan_name
  resource_group_name = azurerm_resource_group.fa_rg.name
  location = local.location
  sku_name = "B1"
  os_type = "Linux"
}

resource "azurerm_application_insights" "func_insight" {
  name                = "fa-application-insights"
  location            = azurerm_resource_group.fa_rg.location
  resource_group_name = azurerm_resource_group.fa_rg.name
  application_type    = "Node.JS"
}

resource "azurerm_linux_function_app" "fa" {
  name = local.fa_name
  resource_group_name = azurerm_resource_group.fa_rg.name
  location = azurerm_resource_group.fa_rg.location
  storage_account_name = azurerm_storage_account.fa_storage_account.name
  storage_account_access_key = azurerm_storage_account.fa_storage_account.primary_access_key
  service_plan_id = azurerm_service_plan.fa_serviceplan.id
  depends_on = [ azurerm_service_plan.fa_serviceplan, azurerm_storage_account.fa_storage_account ]
  https_only                    = true
  public_network_access_enabled = true
  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4",
    "WEBSITE_RUN_FROM_PACKAGE" = "",
    "FUNCTIONS_WORKER_RUNTIME" = "node",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.func_insight.instrumentation_key
  }
  
  site_config {
    application_insights_key               = azurerm_application_insights.func_insight.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.func_insight.connection_string
    application_stack {
      node_version = "20"
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
  tags = local.tags
}
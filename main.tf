terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.36"
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

resource "azurerm_resource_group" "fa_rg" {
  name     = local.rg_name
  location = local.location
  tags = {
    environment = "Azure Functions Resource Group"
  }
}

resource "azurerm_storage_account" "fa_storage_account" {
  name                     = local.storage_account_name
  location                 = azurerm_resource_group.fa_rg.location
  resource_group_name      = azurerm_resource_group.fa_rg.name
  account_kind             = "Storage"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
  timeouts {
    create = "3m"
    update = "3m"
    delete = "3m"
  }

  depends_on = [
    azurerm_resource_group.fa_rg,
  ]
}

resource "azurerm_service_plan" "fa_serviceplan_linux" {
  name                = local.fa_service_plan_linux_name
  resource_group_name = azurerm_resource_group.fa_rg.name
  location            = azurerm_resource_group.fa_rg.location

  os_type  = "Linux"
  sku_name = "B1"

  depends_on = [
    azurerm_resource_group.fa_rg,
  ]
}

resource "azurerm_service_plan" "fa_serviceplan_windows" {
  name                = local.fa_service_plan_windows_name
  resource_group_name = azurerm_resource_group.fa_rg.name
  location            = azurerm_resource_group.fa_rg.location

  os_type  = "Windows"
  sku_name = "Y1"

  depends_on = [
    azurerm_resource_group.fa_rg,
  ]
}

resource "azurerm_log_analytics_workspace" "fa_log_analytics_workspace" {
  location            = azurerm_resource_group.fa_rg.location
  name                = local.fa_log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.fa_rg.name
  depends_on = [
    azurerm_resource_group.fa_rg,
  ]
}

resource "azurerm_application_insights" "func_insight" {
  name                = local.fa_application_insights_name
  location            = azurerm_resource_group.fa_rg.location
  resource_group_name = azurerm_resource_group.fa_rg.name
  workspace_id        = azurerm_log_analytics_workspace.fa_log_analytics_workspace.id
  sampling_percentage = 0
  application_type    = "Node.JS"

  depends_on = [
    azurerm_resource_group.fa_rg,
  ]
}

resource "azurerm_linux_function_app" "fa_linux" {
  name                       = local.fa_name_linux
  resource_group_name        = azurerm_resource_group.fa_rg.name
  location                   = azurerm_resource_group.fa_rg.location
  storage_account_name       = azurerm_storage_account.fa_storage_account.name
  storage_account_access_key = azurerm_storage_account.fa_storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.fa_serviceplan_linux.id

  # https_only                    = true
  # public_network_access_enabled = true
  functions_extension_version = "~4"
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME              = "node",
    WEBSITE_NODE_DEFAULT_VERSION          = "~20"
    APPINSIGHTS_INSTRUMENTATIONKEY        = azurerm_application_insights.func_insight.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.func_insight.connection_string
  }

  site_config {
    # application_insights_key               = azurerm_application_insights.func_insight.instrumentation_key
    # application_insights_connection_string = azurerm_application_insights.func_insight.connection_string
    application_stack {
      node_version = "20"
    }
  }

  tags = local.tags

  depends_on = [
    azurerm_resource_group.fa_rg,
    azurerm_storage_account.fa_storage_account,
    azurerm_service_plan.fa_serviceplan_linux,
    azurerm_application_insights.func_insight,
  ]
}

resource "azurerm_windows_function_app" "fa_windows" {

  builtin_logging_enabled     = false
  client_certificate_mode     = "Required"
  location                    = azurerm_resource_group.fa_rg.location
  name                        = local.fa_name_windows
  resource_group_name         = azurerm_resource_group.fa_rg.name
  service_plan_id             = azurerm_service_plan.fa_serviceplan_windows.id
  storage_account_access_key  = azurerm_storage_account.fa_storage_account.primary_access_key
  storage_account_name        = azurerm_storage_account.fa_storage_account.name
  functions_extension_version = "~4"

  site_config {
    application_insights_connection_string = azurerm_application_insights.func_insight.connection_string
    ftps_state                             = "FtpsOnly"
    ip_restriction_default_action          = "Allow"
    scm_ip_restriction_default_action      = "Allow"
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION"   = "~20",
    "FUNCTIONS_WORKER_RUNTIME" : "node",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.func_insight.connection_string
  }

  depends_on = [
    azurerm_resource_group.fa_rg,
    azurerm_storage_account.fa_storage_account,
    azurerm_service_plan.fa_serviceplan_windows,
    azurerm_application_insights.func_insight,
  ]
}

resource "null_resource" "function_app_publish_windows" {
  depends_on = [local.publish_fa_windows_command, azurerm_windows_function_app.fa_windows]
  triggers = {
    publish_fa_windows_command = local.publish_fa_windows_command
  }
  provisioner "local-exec" {
    command = local.publish_fa_windows_command
  }
}

resource "null_resource" "function_app_publish_linux" {
  depends_on = [local.publish_fa_linux_command, azurerm_windows_function_app.fa_windows]
  triggers = {
    publish_fa_linux_command = local.publish_fa_linux_command
  }
  provisioner "local-exec" {
    command = local.publish_fa_linux_command
  }
}

# resource "azurerm_app_service_custom_hostname_binding" "fa_custom_hostname_binding" {

#   app_service_name    = azurerm_windows_function_app.fa_windows.name
#   hostname            = format("%s%s",local.fa_name_windows, ".azurewebsites.net")
#   resource_group_name = azurerm_resource_group.fa_rg.name

#   depends_on = [
#     azurerm_resource_group.fa_rg,
#   ]
# }

resource "azurerm_monitor_action_group" "fa_monitor_action_group" {
  name                = "Application Insights Smart Detection"
  resource_group_name = azurerm_resource_group.fa_rg.name
  short_name          = "SmartDetect"
  arm_role_receiver {
    name                    = "Monitoring Contributor"
    role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    use_common_alert_schema = true
  }
  arm_role_receiver {
    name                    = "Monitoring Reader"
    role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    use_common_alert_schema = true
  }

  depends_on = [
    azurerm_resource_group.fa_rg,
  ]
}


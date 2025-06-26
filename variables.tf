locals {
  location                        = "westeurope"
  rg_name                         = "azurefa1-rg"
  storage_account_name            = "akazurefa1storage"
  fa_name_linux                   = "akazurefa1linux"
  fa_name_windows                 = "akazurefa1windows"
  fa_service_plan_linux_name      = "ak-azurefa1-service-plan-linux"
  fa_service_plan_windows_name    = "ak-azurefa1-service-plan-windows"
  fa_log_analytics_workspace_name = "ak-azurefa1-log-analytics-workspace"
  fa_application_insights_name    = "ak-azurefa1-app-insights"

  tags = {
    Name = "Azure Functions"
    Env  = "Dev"
  }

}

locals {
  publish_fa_windows_command = "func azure functionapp publish ${azurerm_windows_function_app.fa_windows.name}"
  publish_fa_linux_command   = "func azure functionapp publish ${azurerm_linux_function_app.fa_linux.name}"
}

data "azurerm_user_assigned_identity" "uid" {
  count               = var.identity_type == "UserAssigned" ? 1 : 0
  name                = var.identity
  resource_group_name = var.identity_resource_group
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet
  resource_group_name = var.vnet_rg
}
data "azurerm_subnet" "default-subnet" {
  name                 = var.subnet
  virtual_network_name = var.vnet
  resource_group_name  = var.vnet_rg
}
##Secret Fetching from Azure Keyvault ####
data "azurerm_key_vault" "key_vault" {
  count               = var.keyvault_name != null && var.keyvault_resource_group != null ? 1 : 0 
  name                = var.keyvault_name
  resource_group_name = var.keyvault_resource_group
}

data "azurerm_key_vault_secret" "kvsecrets" {
  for_each     = var.keyvault_secret_names
  name         = each.value
  key_vault_id = data.azurerm_key_vault.key_vault[0].id
}
##Secret Fetching from Azure Keyvault ####

resource "azurerm_resource_group" "function_app_rg" {
  name     = var.resource_group_name
  location = var.location
}

locals {
  subnet_whitelist = "${data.azurerm_subnet.default-subnet.id}" 
}

resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.function_app_rg.name
  location                 = azurerm_resource_group.function_app_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "function_service_plan" {
  name                = "${var.name}-${var.location}-app-service-plan"
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location
  os_type             = var.os_type
  sku_name            = var.sku_name
}

resource "azurerm_windows_function_app" "windows_function_app" {
  count               = var.os_type == "Windows" ? 1 : 0
  name                = var.name
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.function_service_plan.id

  virtual_network_subnet_id = data.azurerm_subnet.default-subnet.id
  app_settings = merge({
    for k, v in data.azurerm_key_vault_secret.kvsecrets :
    k => (v.value)
  }, var.func_app_settings)

  site_config {
    http2_enabled     = true
    health_check_path = var.health_check_path
    use_32_bit_worker = var.use_32_bit_worker
    application_stack {
      dotnet_version              = var.dotnet_version
      use_dotnet_isolated_runtime = var.use_dotnet_isolated_runtime
      java_version                = var.java_version
      node_version                = var.node_version
    }
  }
  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? [data.azurerm_user_assigned_identity.uid[0].id] : null
  }
}

resource "azurerm_linux_function_app" "linux_function_app" {
  count               = var.os_type == "Linux" ? 1 : 0
  name                = var.name
  resource_group_name = azurerm_resource_group.function_app_rg.name
  location            = azurerm_resource_group.function_app_rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.function_service_plan.id

  virtual_network_subnet_id = data.azurerm_subnet.default-subnet.id
  app_settings = merge({
    for k, v in data.azurerm_key_vault_secret.kvsecrets :
    k => (v.value)
  }, var.func_app_settings)
  site_config {
    http2_enabled     = true
    health_check_path = var.health_check_path
    use_32_bit_worker = var.use_32_bit_worker
    application_stack {
      dotnet_version              = var.dotnet_version
      use_dotnet_isolated_runtime = var.use_dotnet_isolated_runtime
      java_version                = var.java_version
      node_version                = var.node_version
    }
  }

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? [data.azurerm_user_assigned_identity.uid[0].id] : null
  }
}

resource "azurerm_resource_group_template_deployment" "enabled_public_access_with_restriction" {
  count               = var.os_type == "Windows" ? 1 : 0
  name                = "${azurerm_windows_function_app.windows_function_app[count.index].name}-network-restrictions"
  resource_group_name = "${azurerm_resource_group.function_app_rg.name}"
  template_content    = <<TEMPLATE
{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "variables": {
     "_force_terraform_to_always_redeploy": "${timestamp()}"
  },
  "resources": [{
     "type": "Microsoft.Web/sites/config",
         "apiVersion": "2023-01-01",
         "name": "${azurerm_windows_function_app.windows_function_app[count.index].name}/web",
         "location": "${azurerm_windows_function_app.windows_function_app[count.index].location}",
         "properties": {
            "ftpsState": "Disabled",
            "ipSecurityRestrictions": [
               {
                  "VnetSubnetResourceId": "${local.subnet_whitelist}",
                  "action": "Allow",
                  "tag": "Default",
                  "priority": 100,
                  "name": "SubnetAllowRule1",
                  "description": ""
               }
            ]
         }
    }
  ]
}
TEMPLATE
  deployment_mode     = "Incremental"
}
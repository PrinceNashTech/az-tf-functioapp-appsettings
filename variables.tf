
variable "resource_group_name" {
  type        = string
  description = "RG name in Azure"
}
variable "location" {
  type        = string
  description = "Resources location in Azure"
}
variable "subnet" {
  type        = string
  description = "Name of the subnet for the Function App."
}
variable "vnet" {
  type        = string
  description = "Name of the vnet required for subnet."
}
variable "vnet_rg" {
  type        = string
  description = "Name of resource group to deploy vnet in."
}

variable "storage_account_name" {
  type        = string
  description = "Backend storage account name to be used by this Function App for dashboard, logs, etc..."
}
variable "name" {
  type        = string
  description = "The name of the Function App."
}
variable "health_check_path" {
  type        = string
  description = "HTTP path to use for checking the health of this Function App."
  default     = null
}
variable "os_type" {
  type        = string
  description = "Either Linux or Windows"
}
variable "sku_name" {
  type        = string
  description = "The SKU for the plan. Possible values include B1, B2, B3, D1, F1, I1, I2, I3, I1v2, I2v2, I3v2, I4v2, I5v2, I6v2, P1v2, P2v2, P3v2, P0v3, P1v3, P2v3, P3v3, P1mv3, P2mv3, P3mv3, P4mv3, P5mv3, S1, S2, S3, SHARED, EP1, EP2, EP3, WS1, WS2, WS3, and Y1."
}

variable "dotnet_version" {
  type        = string
  description = "The version of .NET to use for .NET Function App. Possible values are v3.0, v4.0, v6.0, and v7.0."
  default     = null
}
variable "use_dotnet_isolated_runtime" {
  type        = bool
  description = "Should the .NET process use an isolated runtime"
  default     = null
}
variable "java_version" {
  type        = string
  description = "The version of Java to use. Supported values are 8, 11, and 17"
  default     = null
}
variable "node_version" {
  type        = string
  description = "The version of Node to run. Possible values are 12, 14, 16, and 18"
  default     = null
}
variable "use_32_bit_worker" {
  type        = bool
  description = "Use a 32 bit worker, defaults to false which translates to using a 64 bit worker"
  default     = false
}

variable "identity_type" {
  type        = string
  description = "Could be SystemAssigned or UserAssigned"
  default     = "SystemAssigned"
}
variable "identity" {
  type        = string
  description = "Name of the Managed identity"
  default     = null
}
variable "identity_resource_group" {
  type        = string
  description = "Resource group for identity"
  default     = null
}

variable "func_app_settings" {
  type = map(string)
  description = "Function app settings"
  default = {}
}

variable "keyvault_resource_group" {
  type = string
  description = "Name Of Azure Key Vault Resource Group"
  default = null 
}

variable "keyvault_name" {
  type = string
  description = "Name Of Azure Key Vault"
  default = null
}

variable "keyvault_secret_names" {
  type =map(string)
  description = "kv secrets"
  default = {}
}

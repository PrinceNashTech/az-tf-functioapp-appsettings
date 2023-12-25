output "function_app_id" {
  description = "ID for the deployed Function App"
  value       = length(azurerm_linux_function_app.linux_function_app) > 0 ? azurerm_linux_function_app.linux_function_app[0].id : azurerm_windows_function_app.windows_function_app[0].id
}
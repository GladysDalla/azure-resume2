# Output the website URL
output "website_url" {
  description = "URL of the static website"
  value       = azurerm_storage_account.resume_storage.primary_web_endpoint
}

# Output the Function App URL
output "function_app_url" {
  description = "URL of the Function App"
  value       = azurerm_linux_function_app.resume_function.default_hostname
}

# Output the Function App name for deployment
output "function_app_name" {
  description = "Name of the Function App"
  value       = azurerm_linux_function_app.resume_function.name
}

# Output the storage account name
output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.resume_storage.name
}

# Output the resource group name
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

# Output Application Insights connection string
output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.resume_insights.connection_string
  sensitive   = true
}

# Output Cosmos DB endpoint
output "cosmos_db_endpoint" {
  description = "Cosmos DB endpoint"
  value       = azurerm_cosmosdb_account.resume_cosmos.endpoint
}

# Output Cosmos DB account name
output "cosmos_db_account_name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.resume_cosmos.name
}

# Output Key Vault URI
output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.resume_keyvault.vault_uri
}

# Output Key Vault name
output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.resume_keyvault.name
}

# Output Function App API endpoint for visitor counter
output "visitor_counter_api_url" {
  description = "Full URL for the visitor counter API endpoint"
  value       = "https://${azurerm_linux_function_app.resume_function.default_hostname}/api/visitor"
}

# Output health check API endpoint
output "health_check_api_url" {
  description = "Full URL for the health check API endpoint"
  value       = "https://${azurerm_linux_function_app.resume_function.default_hostname}/api/health"
}

# Output the Function App's managed identity principal ID
output "function_app_principal_id" {
  description = "Principal ID of the Function App's managed identity"
  value       = azurerm_linux_function_app.resume_function.identity[0].principal_id
}

# Output useful deployment information
output "deployment_info" {
  description = "Information needed for deploying the function app"
  value = {
    function_app_name    = azurerm_linux_function_app.resume_function.name
    resource_group_name  = azurerm_resource_group.main.name
    storage_account_name = azurerm_storage_account.resume_storage.name
    key_vault_name      = azurerm_key_vault.resume_keyvault.name
    cosmos_db_name      = azurerm_cosmosdb_account.resume_cosmos.name
  }
}
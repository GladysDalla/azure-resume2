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

# Output Key Vault URI
output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.resume_keyvault.vault_uri
}
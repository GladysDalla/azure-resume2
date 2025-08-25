# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  
  # Disable automatic resource provider registration if you don't have permissions
  skip_provider_registration = true
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = "AzureResumeRG-tf-${random_string.storage_suffix.result}"
  location = "East US 2"
}

# Create a storage account for static website hosting
resource "azurerm_storage_account" "resume_storage" {
  name                     = "azureresume${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = {
    environment = "production"
    project     = "azure-resume"
  }
}

# Random string for unique storage account name
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create Application Insights
resource "azurerm_application_insights" "resume_insights" {
  name                = "azure-resume-insights"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"

  tags = {
    environment = "production"
    project     = "azure-resume"
  }
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "resume_workspace" {
  name                = "azure-resume-workspace"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = "production"
    project     = "azure-resume"
  }
}

# Get current Azure configuration
data "azurerm_client_config" "current" {}

# Create Key Vault (WITHOUT Function App access policy initially)
resource "azurerm_key_vault" "resume_keyvault" {
  name                        = "azure-resume-kv-${random_string.storage_suffix.result}"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  # Only include the current user/service principal access policy initially
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]
  }

  tags = {
    environment = "production"
    project     = "azure-resume"
  }
}

# Store storage connection string in Key Vault
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.resume_storage.primary_connection_string
  key_vault_id = azurerm_key_vault.resume_keyvault.id

  depends_on = [
    azurerm_key_vault.resume_keyvault,
    time_sleep.wait_for_storage
  ]
}

# Add a delay to ensure storage account is fully ready
resource "time_sleep" "wait_for_storage" {
  depends_on = [azurerm_storage_account.resume_storage]

  create_duration = "30s"
}

# Create App Service Plan
resource "azurerm_service_plan" "resume_plan" {
  name                = "azure-resume-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1"

  tags = {
    environment = "production"
    project     = "azure-resume"
  }
}

# Create Function App
resource "azurerm_linux_function_app" "resume_function" {
  name                = "azure-resume-func-${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.resume_storage.name
  storage_account_access_key = azurerm_storage_account.resume_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.resume_plan.id

  site_config {
    application_stack {
      python_version = "3.9"
    }

    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.resume_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.resume_insights.connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "AzureWebJobsFeatureFlags"             = "EnableWorkerIndexing"
    "STORAGE_CONNECTION_STRING"             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection.id})"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "production"
    project     = "azure-resume"
  }

  depends_on = [
    azurerm_key_vault_secret.storage_connection,
    azurerm_storage_account.resume_storage
  ]
}

# SEPARATE Access Policy for Function App Managed Identity
resource "azurerm_key_vault_access_policy" "function_app_policy" {
  key_vault_id = azurerm_key_vault.resume_keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_function_app.resume_function.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]

  depends_on = [azurerm_linux_function_app.resume_function]
}

# Create Cosmos DB Account for visitor counter
resource "azurerm_cosmosdb_account" "resume_cosmos" {
  name                = "azure-resume-cosmos-${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  tags = {
    environment = "production"
    project     = "azure-resume"
  }
}

# Create Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "resume_db" {
  name                = "resumedb"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.resume_cosmos.name
}

# Create Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "visitor_counter" {
  name                  = "visitors"
  resource_group_name   = azurerm_resource_group.main.name
  account_name          = azurerm_cosmosdb_account.resume_cosmos.name
  database_name         = azurerm_cosmosdb_sql_database.resume_db.name
  partition_key_path    = "/id"
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

# Store Cosmos DB connection string in Key Vault
resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = "cosmos-connection-string"
  value        = azurerm_cosmosdb_account.resume_cosmos.primary_sql_connection_string
  key_vault_id = azurerm_key_vault.resume_keyvault.id

  depends_on = [azurerm_key_vault.resume_keyvault]
}
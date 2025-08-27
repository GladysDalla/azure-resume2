# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~>0.9"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  
  # Disable automatic resource provider registration if you don't have permissions
  skip_provider_registration = true
}

# Random string for unique resource names (only where globally unique names are required)
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create a single, consistent resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Create a storage account for static website hosting
resource "azurerm_storage_account" "resume_storage" {
  name                     = "azureresume${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = var.tags
}

# Create Application Insights
resource "azurerm_application_insights" "resume_insights" {
  name                = "${var.project_name}-insights"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"

  tags = var.tags
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "resume_workspace" {
  name                = "${var.project_name}-workspace"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days

  tags = var.tags
}

# Get current Azure configuration
data "azurerm_client_config" "current" {}

# Create Key Vault (WITHOUT Function App access policy initially)
resource "azurerm_key_vault" "resume_keyvault" {
  name                        = "${var.project_name}-kv-${random_string.storage_suffix.result}"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.key_vault_soft_delete_retention_days
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

  tags = var.tags
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
  name                = "${var.project_name}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.function_app_sku

  tags = var.tags
}

# Create Cosmos DB Account for visitor counter (FIXED - removed deprecated enable_automatic_failover)
resource "azurerm_cosmosdb_account" "resume_cosmos" {
  name                = "${var.project_name}-cosmos-${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # REMOVED: enable_automatic_failover = false (deprecated)

  consistency_policy {
    consistency_level       = var.cosmos_consistency_level
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  tags = var.tags
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
  throughput            = var.cosmos_throughput

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

# Create Function App with updated settings for visitor counter (FIXED - removed unsupported arguments)
resource "azurerm_linux_function_app" "resume_function" {
  name                = "${var.project_name}-func-${random_string.storage_suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.resume_storage.name
  storage_account_access_key = azurerm_storage_account.resume_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.resume_plan.id

  site_config {
    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins = ["*"]
      support_credentials = false
    }

    # REMOVED: detailed_error_messages_enabled and failed_request_tracing_enabled
    # These are not supported arguments for azurerm_linux_function_app site_config
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.resume_insights.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.resume_insights.connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "AzureWebJobsFeatureFlags"             = "EnableWorkerIndexing"
    "STORAGE_CONNECTION_STRING"             = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection.id})"
    
    # Key Vault URI for the function to access secrets using Managed Identity
    "KEY_VAULT_URI"                        = azurerm_key_vault.resume_keyvault.vault_uri
    
    # Additional settings for better performance and debugging
    "FUNCTIONS_EXTENSION_VERSION"          = "~4"
    "WEBSITE_RUN_FROM_PACKAGE"             = "1"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"       = "true"
    "ENABLE_ORYX_BUILD"                    = "true"
    
    # Python specific settings
    "PYTHON_ISOLATE_WORKER_DEPENDENCIES"   = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_key_vault_secret.storage_connection,
    azurerm_key_vault_secret.cosmos_connection,
    azurerm_storage_account.resume_storage,
    azurerm_cosmosdb_sql_container.visitor_counter
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
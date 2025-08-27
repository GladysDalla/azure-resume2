# variables.tf - Terraform Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "AzureResumeRG-Terraform"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
  default     = "azure-resume"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "production"
}

variable "storage_account_tier" {
  description = "Storage account performance tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "function_app_sku" {
  description = "Function App service plan SKU"
  type        = string
  default     = "Y1"
}

variable "cosmos_consistency_level" {
  description = "Cosmos DB consistency level"
  type        = string
  default     = "BoundedStaleness"
  validation {
    condition = contains([
      "BoundedStaleness",
      "Eventual",
      "Session",
      "Strong",
      "ConsistentPrefix"
    ], var.cosmos_consistency_level)
    error_message = "Cosmos DB consistency level must be one of: BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix."
  }
}

variable "cosmos_throughput" {
  description = "Cosmos DB container throughput (RU/s)"
  type        = number
  default     = 400
  validation {
    condition     = var.cosmos_throughput >= 400 && var.cosmos_throughput <= 1000000
    error_message = "Cosmos DB throughput must be between 400 and 1,000,000 RU/s."
  }
}

variable "key_vault_soft_delete_retention_days" {
  description = "Key Vault soft delete retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "Key Vault soft delete retention days must be between 7 and 90."
  }
}

variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention period in days"
  type        = number
  default     = 30
  validation {
    condition     = var.log_analytics_retention_days >= 30 && var.log_analytics_retention_days <= 730
    error_message = "Log Analytics retention days must be between 30 and 730."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    project     = "azure-resume"
    environment = "production"
    managed-by  = "terraform"
    purpose     = "portfolio-website"
  }
}
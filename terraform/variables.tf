# variables.tf - Terraform Variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "AzureResumeRG"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
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
}

variable "cosmos_throughput" {
  description = "Cosmos DB container throughput (RU/s)"
  type        = number
  default     = 400
}

variable "key_vault_soft_delete_retention_days" {
  description = "Key Vault soft delete retention period in days"
  type        = number
  default     = 7
}

variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention period in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    project     = "azure-resume"
    environment = "production"
    managed-by  = "terraform"
  }
}
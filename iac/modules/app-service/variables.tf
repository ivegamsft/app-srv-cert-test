variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "prefix" {
  description = "Resource name prefix"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sku_name" {
  description = "SKU name for App Service Plan"
  type        = string
}

variable "runtime_stack" {
  description = "Runtime stack for the App Service"
  type        = string
}

variable "custom_domain" {
  description = "Custom domain for the App Service"
  type        = string
}

variable "enable_custom_domain" {
  description = "Enable custom domain binding"
  type        = bool
  default     = false
}

variable "dns_zone_id" {
  description = "ID of the DNS Zone"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "app_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  type        = string
  default     = ""
}

variable "app_insights_connection_string" {
  description = "Application Insights connection string"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

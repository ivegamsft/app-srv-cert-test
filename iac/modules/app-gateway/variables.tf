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
  description = "SKU name for Application Gateway"
  type        = string
}

variable "capacity" {
  description = "Capacity units for Application Gateway"
  type        = number
}

variable "subnet_id" {
  description = "ID of the subnet for Application Gateway"
  type        = string
}

variable "backend_ip_addresses" {
  description = "List of backend IP addresses"
  type        = list(string)
}

variable "custom_domain" {
  description = "Custom domain name for the Application Gateway"
  type        = string
}

variable "dns_zone_id" {
  description = "ID of the DNS Zone"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "key_vault_secret_id" {
  description = "Secret ID of the SSL certificate in Key Vault"
  type        = string
}

variable "user_assigned_identity_id" {
  description = "ID of the User Assigned Identity"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

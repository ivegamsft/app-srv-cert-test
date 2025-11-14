# General Variables
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "webapp"
}

# Domain and DNS Variables
variable "domain_name" {
  description = "Domain name for the application (e.g., example.com)"
  type        = string
}

variable "enable_custom_domain" {
  description = "Enable custom domain binding (set to true after DNS delegation)"
  type        = bool
  default     = false
}

variable "app_subdomain" {
  description = "Subdomain for the App Service (e.g., app)"
  type        = string
  default     = "app"
}

variable "vm_subdomain" {
  description = "Subdomain for the VM/Application Gateway (e.g., api)"
  type        = string
  default     = "api"
}

# App Service Variables
variable "app_service_sku_name" {
  description = "SKU name for App Service Plan"
  type        = string
  default     = "S1"
}

variable "app_service_runtime" {
  description = "Runtime stack for App Service"
  type        = string
  default     = "NODE|18-lts"
}

# Virtual Machine Variables
variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_DS2_v2"
}

# Application Gateway Variables
variable "app_gateway_sku_name" {
  description = "SKU name for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "app_gateway_capacity" {
  description = "Capacity units for Application Gateway"
  type        = number
  default     = 2
}

# Monitoring Variables
variable "ssl_expiry_alert_days" {
  description = "Days before SSL expiry to trigger alerts"
  type        = list(number)
  default     = [30, 14, 7]
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

# Management workstation public IP (CIDR /32) used to temporarily allow Key Vault access for Terraform
# when public network access is enabled but firewall default action is Deny.
variable "management_ip" {
  description = "Public IP (e.g. 47.206.222.73/32) allowed to access Key Vault during Terraform operations"
  type        = string
  default     = ""
}



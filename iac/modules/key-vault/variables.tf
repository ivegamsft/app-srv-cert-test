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

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "object_id" {
  description = "Object ID of the user/service principal to grant access"
  type        = string
}

variable "vm_admin_username" {
  description = "VM administrator username"
  type        = string
  sensitive   = true
}

variable "vm_admin_password" {
  description = "VM administrator password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "ID of the subnet to associate with the Key Vault"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "ID of the subnet for the Key Vault private endpoint"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network (for private DNS zone link)"
  type        = string
}

# Optional: Subject (common name) for the self-signed certificate
// Removed certificate_subject variable; module will use a sensible default subject for self-signed cert.

# Certificate validity period in months
variable "certificate_validity_months" {
  description = "Validity period for the self-signed certificate in months"
  type        = number
  default     = 12
}

# Days before expiry to auto-renew the certificate
variable "certificate_auto_renew_days" {
  description = "Number of days before expiry to auto-renew the certificate"
  type        = number
  default     = 30
}

# Optional management workstation public IP (CIDR /32) to permit Terraform access while KV is firewalled.
# Leave blank when running Terraform from within the VNet (private endpoint path) for full lock-down.
variable "management_ip" {
  description = "Public IP (e.g. 198.51.100.25/32) allowed to access Key Vault over public network for Terraform operations"
  type        = string
  default     = ""
}

# VM subnet ID used for private (in-VNet) Terraform execution access to Key Vault.
# When running Terraform from the VM inside this subnet, leave management_ip blank and
# the network ACL will permit access via this subnet while keeping public access locked down.
variable "vm_subnet_id" {
  description = "ID of the VM subnet to include in Key Vault network ACL virtual network rules"
  type        = string
  default     = ""
}

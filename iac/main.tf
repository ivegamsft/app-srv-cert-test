# Generate a random DNS-compatible prefix
resource "random_string" "prefix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

# Generate secure VM admin password
resource "random_password" "vm_admin" {
  length           = 24
  special          = true
  override_special = "!@#$%&*()-_=+[]{}:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# Generate VM admin username
resource "random_string" "vm_admin_username" {
  length  = 12
  special = false
  upper   = false
  numeric = true
}

# Derive alert email from domain name
locals {
  alert_email      = "alerts@${var.domain_name}"
  vm_admin_username = "vm-${random_string.vm_admin_username.result}"
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${random_string.prefix.result}-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = random_string.prefix.result
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags
}

# Key Vault Module
module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = random_string.prefix.result
  project_name        = var.project_name
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
  vm_admin_username   = random_string.vm_admin_username.result
  vm_admin_password   = random_password.vm_admin.result
  tags                = var.tags
  subnet_id           = module.networking.appgw_subnet_id
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  vnet_id             = module.networking.vnet_id
  management_ip       = var.management_ip
  vm_subnet_id        = module.networking.vm_subnet_id
}

# DNS Zone for custom domain - Use existing zone from rg-core-services
data "azurerm_dns_zone" "main" {
  name                = var.domain_name
  resource_group_name = "rg-core-services"
}

# App Service Module
module "app_service" {
  source = "./modules/app-service"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = random_string.prefix.result
  project_name        = var.project_name
  environment         = var.environment
  sku_name            = var.app_service_sku_name
  runtime_stack       = var.app_service_runtime
  custom_domain       = "${var.app_subdomain}.${var.domain_name}"
  enable_custom_domain = var.enable_custom_domain
  dns_zone_id         = data.azurerm_dns_zone.main.id
  key_vault_id        = module.key_vault.key_vault_id
  integration_subnet_id = module.networking.app_service_integration_subnet_id
  tags                = var.tags

  depends_on = [module.key_vault]
}

# Virtual Machine Module
module "virtual_machine" {
  source = "./modules/virtual-machine"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  prefix              = random_string.prefix.result
  project_name        = var.project_name
  environment         = var.environment
  vm_size             = var.vm_size
  admin_username      = local.vm_admin_username
  admin_password      = random_password.vm_admin.result
  subnet_id           = module.networking.vm_subnet_id
  key_vault_id        = module.key_vault.key_vault_id
  tags                = var.tags

  depends_on = [module.networking, module.key_vault]
}

# Application Gateway Module
module "app_gateway" {
  source = "./modules/app-gateway"

  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  prefix                = random_string.prefix.result
  project_name          = var.project_name
  environment           = var.environment
  sku_name              = var.app_gateway_sku_name
  capacity              = var.app_gateway_capacity
  subnet_id             = module.networking.appgw_subnet_id
  backend_ip_addresses  = [module.virtual_machine.private_ip_address]
  custom_domain         = "${var.vm_subdomain}.${var.domain_name}"
  dns_zone_id           = data.azurerm_dns_zone.main.id
  key_vault_id          = module.key_vault.key_vault_id
  key_vault_secret_id   = module.key_vault.certificate_secret_id
  user_assigned_identity_id = module.key_vault.user_assigned_identity_id
  tags                  = var.tags

  depends_on = [module.networking, module.virtual_machine, module.key_vault]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  prefix                  = random_string.prefix.result
  project_name            = var.project_name
  environment             = var.environment
  alert_email             = local.alert_email
  ssl_expiry_alert_days   = var.ssl_expiry_alert_days
  app_service_id          = module.app_service.app_service_id
  app_gateway_id          = module.app_gateway.app_gateway_id
  key_vault_id            = module.key_vault.key_vault_id
  tags                    = var.tags

  depends_on = [module.app_service, module.app_gateway, module.key_vault]
}

# User Assigned Managed Identity for Application Gateway to access Key Vault
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "id-appgw-${var.prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.prefix}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true
  rbac_authorization_enabled = true

  # Public network access strategy:
  # - When management_ip is provided (running Terraform from outside Azure VNet), keep public access enabled and
  #   temporarily Allow firewall default_action with that /32 added to ip_rules.
  # - When management_ip is blank (running Terraform from inside the VM subnet), disable public access entirely.
  public_network_access_enabled = var.management_ip != "" ? true : false

  network_acls {
    bypass = "AzureServices"

    # Deny by default when executing from inside VNet; Allow when bootstrapping from a public IP.
    default_action = var.management_ip != "" ? "Allow" : "Deny"

    # Optional single /32 management workstation public IP while bootstrapping.
    ip_rules = var.management_ip != "" ? [var.management_ip] : []

    # Permit access from VM subnet when Terraform runs inside the VNet (private execution path).
    virtual_network_subnet_ids = var.vm_subnet_id != "" ? [var.vm_subnet_id] : []
  }

  tags = var.tags
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "kv_vnet" {
  name                  = "kv-zone-link-${var.prefix}-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "kv" {
  name                = "pe-kv-${var.prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "kv-psc"
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  depends_on = [azurerm_key_vault.main, azurerm_private_dns_zone_virtual_network_link.kv_vnet]
}

# RBAC Role Assignment: Current user as Key Vault Administrator
resource "azurerm_role_assignment" "current_user_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.object_id
}

# RBAC Role Assignment: Application Gateway identity to read secrets and certificates
resource "azurerm_role_assignment" "appgw_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

# Replace self-signed certificate with a placeholder for production-grade certificate
resource "azurerm_key_vault_certificate" "ssl_cert" {
  name         = "ssl-certificate"
  key_vault_id = azurerm_key_vault.main.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }
    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    x509_certificate_properties {
      subject = "CN=example.com"
      validity_in_months = var.certificate_validity_months
      key_usage = ["digitalSignature", "keyEncipherment"]
      # Use OID for Server Authentication EKU
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }
      trigger {
        days_before_expiry = var.certificate_auto_renew_days
      }
    }
  }
}

# Store VM admin username in Key Vault (top-level resource)
resource "azurerm_key_vault_secret" "vm_username" {
  name         = "vm-admin-username"
  value        = var.vm_admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.current_user_admin,
    azurerm_role_assignment.appgw_secrets_user
  ]
}

# Store VM admin password in Key Vault (top-level resource)
resource "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  value        = var.vm_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.current_user_admin,
    azurerm_role_assignment.appgw_secrets_user
  ]
}

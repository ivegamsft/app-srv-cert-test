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
  enable_rbac_authorization  = true

  network_acls {
    default_action = "Allow"  # Change to "Deny" and add specific IPs/VNets for production
    bypass         = "AzureServices"
  }

  tags = var.tags
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

# Create a sample self-signed certificate for initial setup
# Note: Replace this with a real certificate in production
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

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]  # Server Authentication

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=*.${var.prefix}.local"
      validity_in_months = 12

      subject_alternative_names {
        dns_names = [
          "*.${var.prefix}.local",
          "${var.prefix}.local",
        ]
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.current_user_admin
  ]
}

# Store VM admin username in Key Vault
resource "azurerm_key_vault_secret" "vm_username" {
  name         = "vm-admin-username"
  value        = var.vm_admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.current_user_admin
  ]
}

# Store VM admin password in Key Vault
resource "azurerm_key_vault_secret" "vm_password" {
  name         = "vm-admin-password"
  value        = var.vm_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [
    azurerm_role_assignment.current_user_admin
  ]
}

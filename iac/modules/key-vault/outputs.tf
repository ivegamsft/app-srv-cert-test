output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "certificate_secret_id" {
  description = "Secret ID of the SSL certificate"
  value       = azurerm_key_vault_certificate.ssl_cert.secret_id
}

output "user_assigned_identity_id" {
  description = "ID of the User Assigned Identity for Application Gateway"
  value       = azurerm_user_assigned_identity.appgw.id
}

output "user_assigned_identity_principal_id" {
  description = "Principal ID of the User Assigned Identity"
  value       = azurerm_user_assigned_identity.appgw.principal_id
}

output "user_assigned_identity_client_id" {
  description = "Client ID of the User Assigned Identity"
  value       = azurerm_user_assigned_identity.appgw.client_id
}

output "vm_username_secret_id" {
  description = "Secret ID of the VM admin username in Key Vault"
  value       = azurerm_key_vault_secret.vm_username.id
  sensitive   = true
}

output "vm_password_secret_id" {
  description = "Secret ID of the VM admin password in Key Vault"
  value       = azurerm_key_vault_secret.vm_password.id
  sensitive   = true
}

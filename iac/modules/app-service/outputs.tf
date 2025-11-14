output "app_service_id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.main.id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "custom_domain" {
  description = "Custom domain configured for the App Service"
  value       = var.custom_domain
}

output "app_service_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "certificate_thumbprint" {
  description = "Thumbprint of the managed certificate"
  value       = var.enable_custom_domain ? azurerm_app_service_managed_certificate.main[0].thumbprint : null
}

output "custom_domain_enabled" {
  description = "Whether custom domain is enabled"
  value       = var.enable_custom_domain
}
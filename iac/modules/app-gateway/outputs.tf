output "app_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "app_gateway_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = data.azurerm_public_ip.appgw.ip_address
}

output "custom_domain" {
  description = "Custom domain configured for the Application Gateway"
  value       = var.custom_domain
}

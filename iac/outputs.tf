output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_prefix" {
  description = "Random prefix used for resource naming"
  value       = random_string.prefix.result
}

output "dns_zone_name" {
  description = "DNS Zone name"
  value       = data.azurerm_dns_zone.main.name
}

output "dns_zone_nameservers" {
  description = "DNS Zone nameservers (configure these at your domain registrar)"
  value       = data.azurerm_dns_zone.main.name_servers
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = module.app_service.default_hostname
}

output "app_service_name" {
  description = "Name of the App Service (for GitHub Actions)"
  value       = module.app_service.app_service_name
}

output "app_service_custom_domain" {
  description = "Custom domain for the App Service"
  value       = "${var.app_subdomain}.${var.domain_name}"
}

output "app_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = module.app_gateway.public_ip_address
}

output "vm_custom_domain" {
  description = "Custom domain for the VM (via Application Gateway)"
  value       = "${var.vm_subdomain}.${var.domain_name}"
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "vm_private_ip" {
  description = "Private IP address of the Virtual Machine"
  value       = module.virtual_machine.private_ip_address
}

# Generated Credentials (Sensitive)
output "vm_admin_username" {
  description = "Generated VM admin username"
  value       = local.vm_admin_username
  sensitive   = true
}

output "vm_admin_password" {
  description = "Generated VM admin password"
  value       = random_password.vm_admin.result
  sensitive   = true
}

output "alert_email" {
  description = "Alert email derived from domain name"
  value       = local.alert_email
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

output "deployment_instructions" {
  description = "Next steps for deployment"
  value = <<-EOT
    
    ========================================
    DEPLOYMENT SUCCESSFUL
    ========================================
    
    Next Steps:
    
    1. Configure DNS at your domain registrar:
       - Point your domain nameservers to:
         ${join("\n         ", data.azurerm_dns_zone.main.name_servers)}
    
    2. Access your resources:
       - App Service: https://${var.app_subdomain}.${var.domain_name}
       - VM/API Gateway: https://${var.vm_subdomain}.${var.domain_name}
       - Key Vault: ${module.key_vault.key_vault_uri}
    
    3. Retrieve VM credentials (sensitive - store securely):
       - Username: terraform output -raw vm_admin_username
       - Password: terraform output -raw vm_admin_password
    
    4. Upload SSL Certificate to Key Vault:
       - Navigate to Key Vault in Azure Portal
       - Go to Certificates → Generate/Import
       - Upload your certificate or create a self-signed one for testing
    
    5. Monitor SSL Certificate Expiration:
       - Alerts configured for: ${join(", ", var.ssl_expiry_alert_days)} days before expiry
       - Email notifications sent to: ${local.alert_email}
    
    5. Azure Portal Resource Group:
       - https://portal.azure.com/#@/resource/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.main.name}
    
    6. Setup GitHub Actions for CI/CD:
       - Get the publish profile:
         az webapp deployment list-publishing-profiles --name ${module.app_service.app_service_name} --resource-group ${azurerm_resource_group.main.name} --xml
       - Add the XML output as a secret named AZURE_WEBAPP_PUBLISH_PROFILE in your GitHub repository
       - Push code to main/master branch to trigger automatic deployment
    
    ========================================
    EOT
}
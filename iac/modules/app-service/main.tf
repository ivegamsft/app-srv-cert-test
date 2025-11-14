# Extract DNS zone resource group from DNS zone ID
locals {
  dns_zone_rg = element(split("/", var.dns_zone_id), 4)  # /subscriptions/{sub}/resourceGroups/{rg}/providers/...
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.prefix}-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "${split(".", var.custom_domain)[0]}-${var.prefix}-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on = true
    
    application_stack {
      node_version = "18-lts"
    }

    # Enable HTTP/2
    http2_enabled = true
    
    # Minimum TLS version
    minimum_tls_version = "1.2"
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    # Node.js Configuration
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "NODE_ENV"                     = var.environment == "prod" ? "production" : "development"
    
    # Deployment Configuration
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    
    # Application Insights (will be configured after monitoring module creates App Insights)
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.app_insights_instrumentation_key != "" ? var.app_insights_instrumentation_key : null
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string != "" ? var.app_insights_connection_string : null
    
    # Performance
    "WEBSITE_TIME_ZONE" = "UTC"
  }

  lifecycle {
    ignore_changes = [
      app_settings["APPINSIGHTS_INSTRUMENTATIONKEY"],
      app_settings["APPLICATIONINSIGHTS_CONNECTION_STRING"]
    ]
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}

# VNet integration (Swift) for outbound access to private endpoints (Key Vault)
resource "azurerm_app_service_virtual_network_swift_connection" "integration" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = var.integration_subnet_id
}

# DNS CNAME record for custom domain
resource "azurerm_dns_cname_record" "app" {
  name                = split(".", var.custom_domain)[0]
  zone_name           = element(split("/", var.dns_zone_id), length(split("/", var.dns_zone_id)) - 1)
  resource_group_name = local.dns_zone_rg
  ttl                 = 300
  record              = azurerm_linux_web_app.main.default_hostname
}

# DNS TXT record for domain verification
resource "azurerm_dns_txt_record" "app_verification" {
  name                = "asuid.${split(".", var.custom_domain)[0]}"
  zone_name           = element(split("/", var.dns_zone_id), length(split("/", var.dns_zone_id)) - 1)
  resource_group_name = local.dns_zone_rg
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.main.custom_domain_verification_id
  }
}

# Wait for DNS propagation
resource "time_sleep" "wait_for_dns" {
  count = var.enable_custom_domain ? 1 : 0
  
  depends_on = [
    azurerm_dns_cname_record.app,
    azurerm_dns_txt_record.app_verification
  ]

  create_duration = "180s"
}

# Custom domain binding
resource "azurerm_app_service_custom_hostname_binding" "main" {
  count = var.enable_custom_domain ? 1 : 0
  
  hostname            = var.custom_domain
  app_service_name    = azurerm_linux_web_app.main.name
  resource_group_name = var.resource_group_name

  depends_on = [
    time_sleep.wait_for_dns
  ]
}

# App Service Managed Certificate (Free SSL)
resource "azurerm_app_service_managed_certificate" "main" {
  count = var.enable_custom_domain ? 1 : 0
  
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.main[0].id
}

# Bind the managed certificate to the custom domain
resource "azurerm_app_service_certificate_binding" "main" {
  count = var.enable_custom_domain ? 1 : 0
  
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.main[0].id
  certificate_id      = azurerm_app_service_managed_certificate.main[0].id
  ssl_state           = "SniEnabled"
}

# Grant App Service access to Key Vault secrets
resource "azurerm_role_assignment" "app_service_kv_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

# Public IP for Application Gateway
data "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.prefix}-${var.environment}"
  resource_group_name = var.resource_group_name
}

# Local variables
locals {
  backend_address_pool_name      = "backend-pool"
  frontend_port_name_http        = "frontend-port-http"
  dns_zone_rg                    = element(split("/", var.dns_zone_id), 4)  # Extract DNS zone resource group
  frontend_port_name_https       = "frontend-port-https"
  frontend_ip_configuration_name = "frontend-ip-config"
  http_setting_name              = "backend-http-settings"
  listener_name_http             = "http-listener"
  listener_name_https            = "https-listener"
  request_routing_rule_name_http = "routing-rule-http"
  request_routing_rule_name_https = "routing-rule-https"
  redirect_configuration_name    = "redirect-to-https"
  ssl_certificate_name           = "ssl-certificate"
  probe_name                     = "health-probe"
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "appgw-${var.prefix}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku {
    name     = var.sku_name
    tier     = var.sku_name == "Standard_v2" ? "Standard_v2" : "WAF_v2"
    capacity = var.capacity
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  # Frontend IP Configuration
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = data.azurerm_public_ip.appgw.id
  }

  # Frontend Ports
  frontend_port {
    name = local.frontend_port_name_http
    port = 80
  }

  frontend_port {
    name = local.frontend_port_name_https
    port = 443
  }

  # Backend Address Pool
  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = var.backend_ip_addresses
  }

  # Backend HTTP Settings
  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = local.probe_name
  }

  # Health Probe
  probe {
    name                = local.probe_name
    protocol            = "Http"
    path                = "/health"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  # SSL Certificate from Key Vault
  ssl_certificate {
    name                = local.ssl_certificate_name
    key_vault_secret_id = var.key_vault_secret_id
  }

  # HTTP Listener (for redirect to HTTPS)
  http_listener {
    name                           = local.listener_name_http
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name_http
    protocol                       = "Http"
  }

  # HTTPS Listener
  http_listener {
    name                           = local.listener_name_https
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name_https
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_certificate_name
  }

  # Redirect Configuration (HTTP to HTTPS)
  redirect_configuration {
    name                 = local.redirect_configuration_name
    redirect_type        = "Permanent"
    target_listener_name = local.listener_name_https
    include_path         = true
    include_query_string = true
  }

  # Request Routing Rule - HTTP (redirect to HTTPS)
  request_routing_rule {
    name                        = local.request_routing_rule_name_http
    rule_type                   = "Basic"
    http_listener_name          = local.listener_name_http
    redirect_configuration_name = local.redirect_configuration_name
    priority                    = 100
  }

  # Request Routing Rule - HTTPS
  request_routing_rule {
    name                       = local.request_routing_rule_name_https
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name_https
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 110
  }

  # SSL Policy - Use modern TLS 1.2+
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
}

# DNS A record for Application Gateway
resource "azurerm_dns_a_record" "appgw" {
  name                = split(".", var.custom_domain)[0]
  zone_name           = element(split("/", var.dns_zone_id), length(split("/", var.dns_zone_id)) - 1)
  resource_group_name = local.dns_zone_rg
  ttl                 = 300
  records             = [data.azurerm_public_ip.appgw.ip_address]
}

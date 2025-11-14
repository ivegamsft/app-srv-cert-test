# Log Analytics Workspace (created first for App Insights)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.prefix}-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.prefix}-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  tags                = var.tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.prefix}-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = substr("ag-${var.prefix}", 0, 12)
  tags                = var.tags

  email_receiver {
    name                    = "Email Alert"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# Note: App Service certificate expiry alerts not included
# We're using Linux App Service which will use Azure-managed certificates
# that auto-renew. These metrics are only available for custom certificate orders.

# Scheduled Query Rule for Key Vault Certificate Expiry Monitoring
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "keyvault_cert_expiry" {
  name                     = "alert-kv-cert-expiry-${var.prefix}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  description              = "Alert when certificates in Key Vault are expiring"
  severity                 = 1
  enabled                  = true
  auto_mitigation_enabled  = false  # Required for daily frequency (>12h)
  scopes                   = [azurerm_log_analytics_workspace.main.id]
  evaluation_frequency     = "P1D"
  window_duration          = "P1D"
  tags                     = var.tags

  criteria {
    query = <<-QUERY
      AzureDiagnostics
      | where ResourceProvider == "MICROSOFT.KEYVAULT"
      | where OperationName == "CertificateNearExpiry"
      | summarize AggregatedValue = count() by bin(TimeGenerated, 1h)
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
  }
}

# Metric Alert for Application Gateway Health
resource "azurerm_monitor_metric_alert" "app_gateway_health" {
  name                = "alert-appgw-health-${var.prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_gateway_id]
  description         = "Alert when Application Gateway backend health is degraded"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Metric Alert for App Service HTTP Server Errors
resource "azurerm_monitor_metric_alert" "app_service_errors" {
  name                = "alert-appsvc-errors-${var.prefix}"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_id]
  description         = "Alert when App Service has high HTTP 5xx errors"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-kv-${var.prefix}"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"
  }

  # Metrics: enable the default metrics category via the new block
  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic Settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "diag-appgw-${var.prefix}"
  target_resource_id         = var.app_gateway_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  # Metrics: enable the default metrics category via the new block
  enabled_metric {
    category = "AllMetrics"
  }
}

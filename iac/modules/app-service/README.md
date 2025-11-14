# App Service Module

This module manages Azure App Service resources, including the App Service Plan and the Linux Web App.

## Resources

1. **App Service Plan**:
   - Resource: `azurerm_service_plan`
   - Configurable via `variables.tf`.

2. **Linux Web App**:
   - Resource: `azurerm_linux_web_app`
   - Supports Node.js runtime and HTTPS-only configuration.

## Variables

- `prefix`: A unique prefix for resource names.
- `project_name`: The name of the project.
- `environment`: The deployment environment (e.g., `dev`, `prod`).
- `location`: Azure region for deployment.
- `resource_group_name`: Name of the resource group.
- `sku_name`: SKU for the App Service Plan.
- `tags`: Tags for resource organization.
- `custom_domain`: Custom domain name for the web app.
- `dns_zone_id`: DNS Zone ID for custom domain configuration.

## Outputs

- `app_service_url`: The default URL of the deployed web app.
- `app_service_id`: The resource ID of the web app.

## Usage

1. Include the module in your Terraform configuration:
   ```hcl
   module "app_service" {
     source              = "./modules/app-service"
     prefix              = var.prefix
     project_name        = var.project_name
     environment         = var.environment
     location            = var.location
     resource_group_name = azurerm_resource_group.main.name
     sku_name            = var.sku_name
     tags                = var.tags
     custom_domain       = var.custom_domain
     dns_zone_id         = var.dns_zone_id
   }
   ```

2. Apply the Terraform configuration:
   ```sh
   terraform init
   terraform apply
   ```

## Notes
- Ensure that the `variables.tf` file is updated with the required inputs.
- Review the `outputs.tf` file for available outputs.
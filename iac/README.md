# Azure Infrastructure Deployment with Terraform

This repository contains Terraform infrastructure-as-code for deploying a complete Azure solution with:
- **App Service** with Node.js runtime, custom domain, and SSL certificate
- **Virtual Machine** (Windows Server 2022 with IIS) behind Application Gateway
- **Application Gateway** with SSL termination
- **Key Vault** for secrets and certificate management
- **Azure Monitor** with SSL certificate expiration alerts
- **DNS Zone** for custom domain management

## 📋 Architecture Overview

```
Internet
   |
   ├─> Azure DNS Zone
   |     ├─> app.yourdomain.com → App Service (Node.js)
   |     └─> api.yourdomain.com → Application Gateway
   |
   ├─> App Service
   |     ├─> Managed SSL Certificate (Auto-renewal)
   |     └─> System-assigned Managed Identity
   |
   └─> Application Gateway (Public IP)
         ├─> SSL Certificate from Key Vault
         ├─> HTTP → HTTPS Redirect
         └─> Backend Pool
               └─> Virtual Machine (IIS)
                     └─> Private IP (VNet)

Key Vault
   ├─> SSL Certificates
   ├─> Secrets (VM passwords)
   └─> RBAC-based access

Azure Monitor
   ├─> Application Insights
   ├─> Log Analytics Workspace
   └─> Alerts (SSL expiry, health checks)
```

## 🎯 Prerequisites

1. **Azure Subscription**: Active Azure subscription with appropriate permissions
2. **Terraform**: Version 1.5.0 or higher
   ```powershell
   # Install via winget (Windows)
   winget install Hashicorp.Terraform
   ```
3. **Azure CLI**: For authentication
   ```powershell
   # Install Azure CLI
   winget install Microsoft.AzureCLI
   ```
4. **Domain Name**: You'll need to purchase a domain name and configure nameservers

## 🚀 Quick Start

### 1. Clone and Setup

```powershell
cd f:\Git\app-srv-cert-test\iac
```

### 2. Configure Variables

Copy the example variables file and update with your values:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your configuration:

```hcl
# General Configuration
location     = "westeurope"
environment  = "dev"
project_name = "webapp"

# Domain Configuration
domain_name   = "yourdomain.com"      # Replace with your actual domain
app_subdomain = "app"                 # App Service: app.yourdomain.com
vm_subdomain  = "api"                 # VM/AppGW: api.yourdomain.com

# Virtual Machine Configuration
vm_admin_username = "azureadmin"
vm_admin_password = "YourSecurePassword123!"  # Use a strong password

# Monitoring Configuration
alert_email = "your-email@example.com"  # Replace with your email
```

### 3. Authenticate to Azure

```powershell
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 4. Initialize Terraform

```powershell
terraform init
```

### 5. Validate Configuration

```powershell
terraform validate
```

### 6. Plan Deployment

```powershell
terraform plan -out=tfplan
```

Review the plan to ensure all resources are configured correctly.

### 7. Apply Configuration

```powershell
terraform apply tfplan
```

This will take approximately 15-20 minutes to complete.

## 🔧 Post-Deployment Configuration

### 1. Configure DNS Nameservers

After deployment, Terraform will output the DNS nameservers. Configure these at your domain registrar:

```
Outputs:

dns_zone_nameservers = [
  "ns1-01.azure-dns.com.",
  "ns2-01.azure-dns.net.",
  "ns3-01.azure-dns.org.",
  "ns4-01.azure-dns.info.",
]
```

**Steps:**
1. Log in to your domain registrar (GoDaddy, Namecheap, etc.)
2. Navigate to DNS settings
3. Replace existing nameservers with the Azure DNS nameservers above
4. Wait 24-48 hours for DNS propagation

### 2. Upload Production SSL Certificate (Optional)

The infrastructure creates a self-signed certificate for initial testing. For production:

1. Navigate to Azure Portal → Key Vault
2. Go to **Certificates** → **Generate/Import**
3. Upload your production SSL certificate (.pfx or .pem)
4. The certificate will automatically be used by Application Gateway

### 3. Deploy Application Code

#### App Service (Node.js):

```powershell
# Get App Service name
$appServiceName = terraform output -raw app_service_name

# Deploy via ZIP
az webapp deployment source config-zip `
  --resource-group $(terraform output -raw resource_group_name) `
  --name $appServiceName `
  --src path/to/your/app.zip
```

Or use CI/CD integration (GitHub Actions, Azure DevOps).

#### Virtual Machine (IIS):

1. RDP to the VM (IP available in Azure Portal)
2. Deploy your web application to `C:\inetpub\wwwroot\`
3. Configure IIS as needed

### 4. Test Your Deployment

After DNS propagation:

```powershell
# Test App Service
curl https://app.yourdomain.com

# Test VM via Application Gateway
curl https://api.yourdomain.com
```

## 📊 Monitoring and Alerts

### SSL Certificate Monitoring

Alerts are automatically configured for SSL certificate expiration:
- **30 days** before expiry (Warning)
- **14 days** before expiry (High)
- **7 days** before expiry (Critical)

Email notifications will be sent to the configured `alert_email`.

### Application Insights

Access Application Insights in Azure Portal:
```powershell
az monitor app-insights component show `
  --resource-group $(terraform output -raw resource_group_name) `
  --app appi-*
```

### View Logs

```powershell
# App Service logs
az webapp log tail `
  --resource-group $(terraform output -raw resource_group_name) `
  --name $(terraform output -raw app_service_name)

# Application Gateway logs (via Log Analytics)
# Access through Azure Portal → Log Analytics Workspace
```

## 🔐 Security Features

- ✅ **Managed Identities**: System-assigned for App Service and VM
- ✅ **Key Vault RBAC**: Role-based access control (no access policies)
- ✅ **Purge Protection**: Enabled on Key Vault
- ✅ **Network Security Groups**: Least-privilege network rules
- ✅ **HTTPS Only**: Forced SSL/TLS on all endpoints
- ✅ **HTTP → HTTPS Redirect**: Automatic on Application Gateway
- ✅ **TLS 1.2 Minimum**: Enforced on all services
- ✅ **Private Networking**: VM isolated in private subnet

## 🛠️ Common Operations

### Update Infrastructure

```powershell
terraform plan
terraform apply
```

### Destroy Infrastructure

```powershell
# ⚠️ WARNING: This will delete all resources!
terraform destroy
```

### Scale App Service

Update `terraform.tfvars`:
```hcl
app_service_sku_name = "P1v2"  # Premium tier
```

Then apply:
```powershell
terraform apply
```

### Add Additional Backend VMs

Update the VM module to create multiple instances or use VM Scale Sets.

## 📝 Resource Naming Convention

All resources use the format: `<type>-<random-prefix>-<project>-<env>`

Example:
- Resource Group: `rg-abc12345-webapp-dev`
- App Service: `app-abc12345-webapp-dev`
- Key Vault: `kv-abc12345-dev`
- VM: `vm-abc12345-dev`

The random prefix ensures globally unique names for resources like Key Vault and App Service.

## 💰 Cost Estimation

Approximate monthly costs (West Europe region):

| Resource | SKU | Est. Cost (USD/month) |
|----------|-----|----------------------|
| App Service Plan | S1 | ~$70 |
| Virtual Machine | Standard_DS2_v2 | ~$100 |
| Application Gateway | Standard_v2 (2 units) | ~$250 |
| Key Vault | Standard | ~$5 |
| Azure Monitor | Log Analytics + Alerts | ~$20 |
| DNS Zone | 1 zone + queries | ~$1 |
| **Total** | | **~$446/month** |

> Costs are estimates. Actual costs may vary based on usage and region.

## 🔍 Troubleshooting

### Issue: DNS not resolving

**Solution**: 
- Verify nameservers are configured correctly at registrar
- Wait up to 48 hours for DNS propagation
- Test with `nslookup yourdomain.com`

### Issue: App Service 503 error

**Solution**:
- Check Application Insights for errors
- Verify application code is deployed
- Check App Service logs in Azure Portal

### Issue: Application Gateway backend unhealthy

**Solution**:
- Verify VM is running and IIS is started
- Check NSG rules allow traffic from AppGW subnet
- Review health probe configuration
- Check VM firewall allows HTTP/HTTPS

### Issue: Certificate errors

**Solution**:
- Verify certificate is uploaded to Key Vault
- Check Application Gateway identity has access to Key Vault
- Ensure certificate is in correct format (.pfx)

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure Application Gateway Documentation](https://docs.microsoft.com/azure/application-gateway/)
- [Azure Key Vault Documentation](https://docs.microsoft.com/azure/key-vault/)
- [Azure Monitor Documentation](https://docs.microsoft.com/azure/azure-monitor/)

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure resource logs in the Portal
3. Examine Terraform state: `terraform show`

## 📄 License

This infrastructure code is provided as-is for use in your Azure environment.

---

**Generated Resource Prefix**: Check `terraform output resource_prefix` after deployment

**Deployment Time**: Approximately 15-20 minutes

**Last Updated**: November 2025

# Quick Start Guide

Get your Azure infrastructure deployed in under 30 minutes!

## ⚡ Prerequisites (5 minutes)

1. **Install Terraform**:
   ```powershell
   winget install Hashicorp.Terraform
   ```

2. **Install Azure CLI**:
   ```powershell
   winget install Microsoft.AzureCLI
   ```

3. **Verify installations**:
   ```powershell
   terraform --version  # Should show 1.5.0 or higher
   az --version         # Should show Azure CLI
   ```

## 🚀 Deploy Infrastructure (20 minutes)

### Step 1: Configure (2 minutes)

```powershell
# Navigate to infrastructure folder
cd f:\Git\app-srv-cert-test\iac

# Copy and edit configuration
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

**Update these required values**:
```hcl
domain_name  = "yourdomain.com"           # Your domain
alert_email  = "your-email@example.com"   # Your email
vm_admin_password = "YourSecure123!Pass"  # Strong password
```

### Step 2: Login to Azure (1 minute)

```powershell
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 3: Deploy (15 minutes)

```powershell
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy (confirm with 'yes')
terraform apply
```

⏱️ **Deployment takes approximately 15-20 minutes**

### Step 4: Save Outputs (2 minutes)

```powershell
# Save DNS nameservers
terraform output dns_zone_nameservers

# Save all outputs
terraform output > deployment-info.txt
```

## 🌐 Configure DNS (2 minutes + wait time)

1. Copy the nameservers from the output
2. Go to your domain registrar (GoDaddy, Namecheap, etc.)
3. Update DNS nameservers
4. **Wait 24-48 hours** for DNS propagation

## 📱 Deploy Sample App (5 minutes)

```powershell
# Navigate to app folder
cd ..\app

# Install dependencies
npm install

# Get your App Service name
$appName = terraform -chdir=..\iac output -raw app_service_name
$rgName = terraform -chdir=..\iac output -raw resource_group_name

# Deploy application
Compress-Archive -Path * -DestinationPath app.zip -Force
az webapp deployment source config-zip `
  --resource-group $rgName `
  --name $appName `
  --src app.zip
```

## ✅ Verify Deployment

### Check Resources in Azure Portal

```powershell
# Open resource group in browser
$rgName = terraform -chdir=iac output -raw resource_group_name
Start-Process "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$rgName"
```

### Test Endpoints (after DNS propagation)

```powershell
# Test App Service
curl https://app.yourdomain.com

# Test Application Gateway
curl https://api.yourdomain.com
```

## 📊 View Monitoring

```powershell
# View Application Insights
az monitor app-insights component show `
  --resource-group $rgName `
  --app appi-* `
  --query name
```

## 🎯 Next Steps

- ✅ Deploy your actual application code
- ✅ Upload production SSL certificate to Key Vault (optional)
- ✅ Configure CI/CD pipeline
- ✅ Set up cost alerts
- ✅ Review monitoring dashboards

## 🆘 Troubleshooting

### Terraform Errors

```powershell
# Check Terraform version
terraform --version

# Reinitialize if needed
terraform init -upgrade

# Validate configuration
terraform validate
```

### Azure Authentication Issues

```powershell
# Clear and re-login
az account clear
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Deployment Stuck

- Check Azure Portal for resource status
- Review logs: `terraform show`
- Check for quota limits: Azure Portal → Quotas

### DNS Not Resolving

```powershell
# Check nameservers
nslookup -type=NS yourdomain.com

# Wait 24-48 hours for propagation
```

## 📋 Useful Commands

```powershell
# View all Terraform outputs
terraform output

# View specific output
terraform output dns_zone_nameservers
terraform output app_service_custom_domain

# Update infrastructure
terraform plan
terraform apply

# View App Service logs
az webapp log tail --resource-group $rgName --name $appName

# View resource costs
az consumption usage list --start-date 2025-11-01 --end-date 2025-11-30

# Destroy everything (⚠️ DANGER)
terraform destroy
```

## 💡 Tips

1. **Save your terraform outputs** - You'll need them later
2. **Use strong passwords** - Store them in a password manager
3. **Enable cost alerts** - Avoid surprise bills
4. **Test in dev first** - Create a dev environment before production
5. **Backup state file** - Keep your terraform.tfstate safe

## 🔗 Resources

- [Full Documentation](README.md)
- [Deployment Checklist](DEPLOYMENT_CHECKLIST.md)
- [Architecture Details](ARCHITECTURE.md)
- [IaC README](iac/README.md)

---

**Estimated Total Time**: 30 minutes + DNS propagation (24-48 hours)  
**Cost**: ~$446/month  
**Support**: See troubleshooting section above

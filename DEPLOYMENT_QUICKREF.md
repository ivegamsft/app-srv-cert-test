# Quick Deployment Reference

## Get Publish Profile for GitHub Actions

```powershell
# Navigate to infrastructure directory
cd f:\Git\app-srv-cert-test\iac

# Get App Service name
$appName = terraform output -raw app_service_name
$rgName = terraform output -raw resource_group_name

# Get publish profile (copy output to GitHub secret)
az webapp deployment list-publishing-profiles `
  --name $appName `
  --resource-group $rgName `
  --xml
```

## Configure App Insights

```powershell
# Get Application Insights credentials
$appInsightsKey = terraform output -raw application_insights_instrumentation_key
$appInsightsConn = terraform output -raw application_insights_connection_string

# Update App Service settings
az webapp config appsettings set `
  --name $appName `
  --resource-group $rgName `
  --settings `
    APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey `
    APPLICATIONINSIGHTS_CONNECTION_STRING=$appInsightsConn `
    NODE_ENV=production
```

## Manual App Deployment (Without GitHub Actions)

```powershell
# Navigate to app directory
cd f:\Git\app-srv-cert-test\app

# Install dependencies
npm install

# Create deployment package
Compress-Archive -Path * -DestinationPath deploy.zip -Force

# Deploy to Azure
az webapp deployment source config-zip `
  --name $appName `
  --resource-group $rgName `
  --src deploy.zip
```

## View App Settings

```powershell
# List all app settings
az webapp config appsettings list `
  --name $appName `
  --resource-group $rgName `
  --output table
```

## View Deployment Logs

```powershell
# Stream logs from App Service
az webapp log tail `
  --name $appName `
  --resource-group $rgName
```

## Restart App Service

```powershell
# Restart the app service
az webapp restart `
  --name $appName `
  --resource-group $rgName
```

## Test Endpoints

```powershell
# Test health endpoint
$defaultUrl = terraform output -raw app_service_default_hostname
curl "https://$defaultUrl/health"

# Test main app
$customDomain = terraform output -raw app_service_custom_domain
Start-Process "https://$customDomain"
```

## GitHub Secret Configuration

1. **Get publish profile** (run command above)
2. **Go to GitHub**: Settings > Secrets and variables > Actions
3. **Add secret**:
   - Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - Value: (paste XML from publish profile command)
4. **Push to main branch** to trigger deployment

## Automated Setup Script

```powershell
# Run the automated setup script
.\setup-github-actions.ps1
```

This script will:
- Get and display the publish profile
- Copy publish profile to clipboard
- Optionally configure Application Insights
- Show next steps for GitHub configuration

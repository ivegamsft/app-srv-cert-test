# Setup GitHub Actions Deployment
# This script helps configure GitHub Actions deployment for the Azure App Service

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Actions Deployment Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to IAC directory
Set-Location -Path "$PSScriptRoot\iac"

# Get Terraform outputs
Write-Host "Getting Terraform outputs..." -ForegroundColor Yellow
$appServiceName = terraform output -raw app_service_name
$resourceGroupName = terraform output -raw resource_group_name
$appInsightsKey = terraform output -raw application_insights_instrumentation_key
$appInsightsConn = terraform output -raw application_insights_connection_string

Write-Host "App Service Name: $appServiceName" -ForegroundColor Green
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor Green
Write-Host ""

# Step 1: Get Publish Profile
Write-Host "Step 1: Get Publish Profile" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Fetching publish profile from Azure..." -ForegroundColor Yellow

$publishProfile = az webapp deployment list-publishing-profiles `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --xml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Publish profile retrieved successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Copy the following XML and add it as a GitHub secret:" -ForegroundColor Yellow
    Write-Host "Secret Name: AZURE_WEBAPP_PUBLISH_PROFILE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "--- BEGIN PUBLISH PROFILE ---" -ForegroundColor Gray
    Write-Host $publishProfile
    Write-Host "--- END PUBLISH PROFILE ---" -ForegroundColor Gray
    Write-Host ""
    
    # Copy to clipboard if available
    try {
        $publishProfile | Set-Clipboard
        Write-Host "✅ Publish profile copied to clipboard!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not copy to clipboard. Please copy manually." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Failed to get publish profile. Make sure you're logged in to Azure CLI:" -ForegroundColor Red
    Write-Host "   az login" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "Step 2: Configure Application Insights" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$response = Read-Host "Do you want to configure Application Insights now? (y/n)"

if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host "Updating App Service settings..." -ForegroundColor Yellow
    
    az webapp config appsettings set `
        --name $appServiceName `
        --resource-group $resourceGroupName `
        --settings `
            APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey `
            APPLICATIONINSIGHTS_CONNECTION_STRING=$appInsightsConn
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Application Insights configured successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to configure Application Insights" -ForegroundColor Red
    }
} else {
    Write-Host "Skipped Application Insights configuration." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To configure later, run:" -ForegroundColor Gray
    Write-Host "az webapp config appsettings set \`" -ForegroundColor Gray
    Write-Host "  --name $appServiceName \`" -ForegroundColor Gray
    Write-Host "  --resource-group $resourceGroupName \`" -ForegroundColor Gray
    Write-Host "  --settings \`" -ForegroundColor Gray
    Write-Host "    APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey \`" -ForegroundColor Gray
    Write-Host "    APPLICATIONINSIGHTS_CONNECTION_STRING=$appInsightsConn" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 3: Update GitHub Workflow" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The workflow file is located at:" -ForegroundColor Yellow
Write-Host "  .github/workflows/deploy.yml" -ForegroundColor Gray
Write-Host ""
Write-Host "Verify the AZURE_WEBAPP_NAME is correct:" -ForegroundColor Yellow
Write-Host "  AZURE_WEBAPP_NAME: '$appServiceName'" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Add GitHub Secret" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Go to your GitHub repository" -ForegroundColor White
Write-Host "2. Navigate to Settings, then Secrets and variables, then Actions" -ForegroundColor White
Write-Host "3. Click 'New repository secret'" -ForegroundColor White
Write-Host "4. Name: AZURE_WEBAPP_PUBLISH_PROFILE" -ForegroundColor Green
Write-Host "5. Value: (paste the XML from above)" -ForegroundColor Green
Write-Host "6. Click 'Add secret'" -ForegroundColor White
Write-Host ""

Write-Host "Step 5: Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Push your code to trigger deployment:" -ForegroundColor Yellow
Write-Host "  git add ." -ForegroundColor Gray
Write-Host "  git commit -m 'Add deployment workflow'" -ForegroundColor Gray
Write-Host "  git push origin main" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your application will be available at:" -ForegroundColor Yellow
$defaultHostname = terraform output -raw app_service_default_hostname
$customDomain = terraform output -raw app_service_custom_domain
Write-Host "  https://$defaultHostname" -ForegroundColor Green
Write-Host "  https://$customDomain" -ForegroundColor Green
Write-Host ""

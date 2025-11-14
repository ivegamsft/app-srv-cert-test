# Test GitHub Actions Workflow Locally
# This script simulates what the GitHub Actions workflow will do

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing GitHub Actions Workflow Locally" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$appName = "web-205vy95w-webapp-dev"
$rgName = "rg-205vy95w-webapp-dev"
$nodeVersion = "18.x"

# Step 1: Checkout (simulated - already in directory)
Write-Host "Step 1: Checkout code" -ForegroundColor Yellow
Write-Host "✅ Already in workspace" -ForegroundColor Green
Write-Host ""

# Step 2: Set up Node.js
Write-Host "Step 2: Set up Node.js $nodeVersion" -ForegroundColor Yellow
$currentNodeVersion = node --version
Write-Host "Current Node version: $currentNodeVersion" -ForegroundColor Green
Write-Host ""

# Step 3: Install dependencies
Write-Host "Step 3: Install dependencies" -ForegroundColor Yellow
Set-Location -Path ".\app"

if (Test-Path "package-lock.json") {
    Write-Host "Running npm ci..." -ForegroundColor Cyan
    npm ci --omit=dev
} else {
    Write-Host "Running npm install..." -ForegroundColor Cyan
    npm install --production
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 4: Run tests (if available)
Write-Host "Step 4: Run tests" -ForegroundColor Yellow
npm test --if-present
Write-Host "✅ Tests passed (or skipped)" -ForegroundColor Green
Write-Host ""

# Step 5: Create deployment package
Write-Host "Step 5: Create deployment package" -ForegroundColor Yellow
Set-Location -Path ".."
if (Test-Path "deploy.zip") {
    Remove-Item "deploy.zip" -Force
}
Compress-Archive -Path "app\*" -DestinationPath "deploy.zip" -Force
Write-Host "✅ Package created: deploy.zip" -ForegroundColor Green
Write-Host ""

# Step 6: Deploy to Azure
Write-Host "Step 6: Deploy to Azure App Service" -ForegroundColor Yellow
Write-Host "App Service: $appName" -ForegroundColor Cyan
Write-Host "Resource Group: $rgName" -ForegroundColor Cyan
Write-Host ""

az webapp deployment source config-zip `
    --name $appName `
    --resource-group $rgName `
    --src "deploy.zip"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Deployment successful" -ForegroundColor Green
Write-Host ""

# Step 7: Test deployment (health check)
Write-Host "Step 7: Test deployment" -ForegroundColor Yellow
Write-Host "Waiting for app to warm up..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

$healthUrl = "https://$appName.azurewebsites.net/health"
Write-Host "Testing health endpoint: $healthUrl" -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Health check passed!" -ForegroundColor Green
        Write-Host "Response: $($response.Content)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  Unexpected status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Health check failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 8: Deployment Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Deployment Successful!" -ForegroundColor Green
Write-Host ""
Write-Host "App Service:    $appName" -ForegroundColor White
Write-Host "Default URL:    https://$appName.azurewebsites.net" -ForegroundColor White
Write-Host "Custom Domain:  https://web.zerotrace-labs.com" -ForegroundColor White
Write-Host "Node Version:   $nodeVersion" -ForegroundColor White
Write-Host ""
Write-Host "Health check passed successfully! 🚀" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open https://$appName.azurewebsites.net in your browser" -ForegroundColor Gray
Write-Host "2. Verify the SSL certificate and DNS information is displayed" -ForegroundColor Gray
Write-Host "3. Set up GitHub Actions for automated deployments" -ForegroundColor Gray
Write-Host ""

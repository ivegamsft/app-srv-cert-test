# Test Local Deployment
# Quick script to test the app locally before deploying to Azure

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Local Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to app directory
Set-Location -Path "$PSScriptRoot\app"

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
} else {
    Write-Host "✅ Dependencies already installed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting local server..." -ForegroundColor Yellow
Write-Host "The app will be available at: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "The page will show:" -ForegroundColor White
Write-Host "  • SSL/TLS connection status (will show HTTP locally)" -ForegroundColor Gray
Write-Host "  • DNS bindings and hostname information" -ForegroundColor Gray
Write-Host "  • Request details and timestamps" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the server
npm start

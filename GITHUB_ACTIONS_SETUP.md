# GitHub Actions Deployment Setup

This guide explains how to set up automated deployment of the Node.js application to Azure App Service using GitHub Actions.

## Prerequisites

- Azure subscription with deployed infrastructure (via Terraform)
- GitHub repository with your code
- Azure CLI installed locally

## Step 1: Get Azure App Service Details

After deploying the infrastructure with Terraform, get the App Service name:

```powershell
cd f:\Git\app-srv-cert-test\iac
terraform output app_service_name
```

The output should be: `web-205vy95w-webapp-dev`

## Step 2: Get Publish Profile

Get the publish profile from Azure (this contains deployment credentials):

```powershell
az webapp deployment list-publishing-profiles `
  --name web-205vy95w-webapp-dev `
  --resource-group rg-205vy95w-webapp-dev `
  --xml
```

This will output XML content. Copy the entire XML output.

## Step 3: Add GitHub Secret

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
5. Value: Paste the entire XML from Step 2
6. Click **Add secret**

## Step 4: Update Workflow File (if needed)

The workflow file is located at `.github/workflows/deploy.yml`. 

If your App Service name is different, update the `AZURE_WEBAPP_NAME` environment variable:

```yaml
env:
  AZURE_WEBAPP_NAME: 'web-205vy95w-webapp-dev'  # Update this if different
```

## Step 5: Configure Application Insights (Optional)

To enable Application Insights monitoring, update the app service settings:

```powershell
# Get the Application Insights instrumentation key
$appInsightsKey = terraform output -raw application_insights_instrumentation_key
$appInsightsConn = terraform output -raw application_insights_connection_string

# Update App Service settings
az webapp config appsettings set `
  --name web-205vy95w-webapp-dev `
  --resource-group rg-205vy95w-webapp-dev `
  --settings `
    APPINSIGHTS_INSTRUMENTATIONKEY=$appInsightsKey `
    APPLICATIONINSIGHTS_CONNECTION_STRING=$appInsightsConn
```

## Step 6: Deploy

Push your code to the `main` or `master` branch:

```powershell
git add .
git commit -m "Add deployment workflow"
git push origin main
```

The GitHub Actions workflow will automatically:
1. Build the Node.js application
2. Run tests (if available)
3. Deploy to Azure App Service
4. Test the deployment with a health check

## Step 7: Verify Deployment

Check the deployment:

1. **GitHub Actions**: Go to your repository's **Actions** tab to see the workflow run
2. **App Service URL**: Visit https://web-205vy95w-webapp-dev.azurewebsites.net
3. **Custom Domain**: Visit https://web.zerotrace-labs.com (if DNS is configured)

## Workflow Features

The GitHub Actions workflow includes:

- **Automatic Triggers**: Deploys on push to main/master or when app files change
- **Manual Trigger**: Can be triggered manually via workflow_dispatch
- **Node.js Caching**: Speeds up builds by caching npm dependencies
- **Health Check**: Validates deployment by calling `/health` endpoint
- **Deployment Summary**: Shows deployment details in GitHub Actions summary

## Troubleshooting

### Workflow Fails at Deploy Step

- Verify the `AZURE_WEBAPP_PUBLISH_PROFILE` secret is set correctly
- Ensure the App Service name matches in the workflow file
- Check that the App Service is running in Azure Portal

### Health Check Fails

- The app might need more time to start. Increase the sleep time in the workflow
- Check App Service logs in Azure Portal under **Monitoring** > **Log stream**
- Verify the `/health` endpoint exists and returns 200 status

### App Settings Not Applied

- Run the Azure CLI command to manually update app settings
- Check current settings:
  ```powershell
  az webapp config appsettings list --name web-205vy95w-webapp-dev --resource-group rg-205vy95w-webapp-dev
  ```

## Environment Variables

The following environment variables are automatically configured by Terraform:

- `NODE_ENV`: Set to `development` or `production` based on environment
- `WEBSITE_NODE_DEFAULT_VERSION`: Node.js version (~18)
- `SCM_DO_BUILD_DURING_DEPLOYMENT`: Enables build during deployment
- `WEBSITE_RUN_FROM_PACKAGE`: Enables running from package
- `WEBSITE_TIME_ZONE`: Set to UTC

Application Insights variables (configured manually):
- `APPINSIGHTS_INSTRUMENTATIONKEY`: Application Insights instrumentation key
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights connection string

## Updating the Workflow

To modify the deployment process, edit `.github/workflows/deploy.yml`:

- Change Node.js version: Update `NODE_VERSION`
- Add build steps: Add steps in the `build` job
- Modify deployment: Update the `deploy` job
- Add environments: Configure deployment environments in GitHub

## Manual Deployment (Alternative)

If you prefer to deploy manually without GitHub Actions:

```powershell
cd f:\Git\app-srv-cert-test\app
npm install
az webapp deployment source config-zip `
  --name web-205vy95w-webapp-dev `
  --resource-group rg-205vy95w-webapp-dev `
  --src (Compress-Archive -Path * -DestinationPath ../deploy.zip -PassThru).FullName
```

## Monitoring Deployments

- **Azure Portal**: App Service > **Deployment Center** shows deployment history
- **GitHub Actions**: Repository > **Actions** tab shows all workflow runs
- **Application Insights**: Monitor app performance and errors in Azure Portal

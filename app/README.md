# Sample Node.js Application for Azure App Service

This is a simple Node.js/Express application that can be deployed to Azure App Service.

## Features

- ✅ Express.js web server
- ✅ Health check endpoint
- ✅ API endpoints
- ✅ Error handling
- ✅ Graceful shutdown
- ✅ Azure App Service optimized

## Local Development

### Prerequisites

- Node.js 18.x or higher
- npm

### Installation

```bash
npm install
```

### Run Locally

```bash
npm start
```

Or with auto-reload:

```bash
npm run dev
```

Visit `http://localhost:3000`

## Environment Variables

- `PORT`: The port on which the application runs (default: `3000`).

## Notes

- Ensure that the Azure App Service is configured to use Node.js runtime version `18-lts`.
- Refer to the `package.json` file for additional scripts and dependencies.

## Endpoints

- `GET /` - Homepage
- `GET /health` - Health check
- `GET /api/info` - Application information

## Deployment to Azure

### Option 1: ZIP Deployment

```powershell
# Build ZIP file
Compress-Archive -Path * -DestinationPath app.zip

# Deploy
az webapp deployment source config-zip `
  --resource-group <resource-group-name> `
  --name <app-service-name> `
  --src app.zip
```

### Option 2: Git Deployment

```bash
# Get deployment credentials
az webapp deployment list-publishing-credentials `
  --resource-group <resource-group-name> `
  --name <app-service-name>

# Add Git remote and push
git init
git add .
git commit -m "Initial commit"
git remote add azure <git-url>
git push azure main
```

### Option 3: GitHub Actions (CI/CD)

1. Create `.github/workflows/deploy.yml`
2. Add publish profile secret to GitHub repository
3. Push to trigger deployment

## Monitoring

- Use Application Insights for monitoring
- Check logs: `az webapp log tail --resource-group <rg> --name <app-name>`

## License

MIT

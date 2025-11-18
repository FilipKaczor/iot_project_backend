#!/bin/bash

# Azure Deployment Script
# Run this to deploy backend to Azure App Service

set -e

echo "Starting Azure deployment..."

# Configuration
RESOURCE_GROUP="iot-project-rg"
APP_SERVICE_PLAN="iot-project-plan"
WEB_APP_NAME="iot-api-$(date +%s)"  # Unique name with timestamp
LOCATION="westeurope"

echo "Web App Name: $WEB_APP_NAME"

# 1. Login to Azure
echo "Step 1: Azure login..."
az login

# 2. Create resource group (if doesn't exist)
echo "Step 2: Creating resource group..."
az group create --name $RESOURCE_GROUP --location $LOCATION || true

# 3. Create App Service Plan (Free tier F1)
echo "Step 3: Creating App Service Plan..."
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku F1 \
  --is-linux \
  || echo "App Service Plan already exists"

# 4. Create Web App
echo "Step 4: Creating Web App..."
az webapp create \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET:8.0"

# 5. Configure Web App settings
echo "Step 5: Configuring application settings..."
echo "NOTE: You need to set these manually or provide values:"
echo "  - ConnectionStrings__DefaultConnection"
echo "  - JwtSettings__SecretKey"
echo "  - AzureIoTHub__ConnectionString"
echo "  - AzureIoTHub__EventHubConnectionString"

# Example (replace with your values):
# az webapp config appsettings set \
#   --name $WEB_APP_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --settings \
#     ConnectionStrings__DefaultConnection="Server=..." \
#     JwtSettings__SecretKey="your-secret-key-min-32-chars" \
#     AzureIoTHub__ConnectionString="HostName=..." \
#     AzureIoTHub__EventHubConnectionString="Endpoint=..."

# 6. Build and publish
echo "Step 6: Building application..."
cd IoTProject.API
dotnet publish -c Release -o ./publish

# 7. Create deployment package
echo "Step 7: Creating deployment package..."
cd publish
zip -r ../deploy.zip .
cd ..

# 8. Deploy to Azure
echo "Step 8: Deploying to Azure..."
az webapp deploy \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --src-path deploy.zip \
  --type zip

# 9. Restart app
echo "Step 9: Restarting application..."
az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

echo ""
echo "=========================================="
echo "Deployment complete!"
echo "=========================================="
echo ""
echo "Your API is available at:"
echo "https://$WEB_APP_NAME.azurewebsites.net"
echo ""
echo "Swagger UI:"
echo "https://$WEB_APP_NAME.azurewebsites.net/swagger"
echo ""
echo "Share this URL with your team!"
echo ""
echo "Next steps:"
echo "1. Configure app settings in Azure Portal"
echo "2. Test: curl https://$WEB_APP_NAME.azurewebsites.net/health"
echo "3. Update mobile app API_BASE_URL to this URL"
echo ""



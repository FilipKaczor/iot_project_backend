# Azure Deployment Script (PowerShell)
# Run this to deploy backend to Azure App Service

$ErrorActionPreference = "Stop"

Write-Host "Starting Azure deployment..." -ForegroundColor Green

# Configuration
$RESOURCE_GROUP = "iot-project-rg"
$APP_SERVICE_PLAN = "iot-project-plan"
$WEB_APP_NAME = "iot-api-$(Get-Date -Format 'yyyyMMddHHmmss')"  # Unique name
$LOCATION = "westeurope"

Write-Host "Web App Name: $WEB_APP_NAME" -ForegroundColor Yellow

# 1. Login to Azure
Write-Host "`nStep 1: Azure login..." -ForegroundColor Cyan
az login

# 2. Create resource group (if doesn't exist)
Write-Host "`nStep 2: Creating resource group..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP --location $LOCATION 2>$null

# 3. Create App Service Plan (Free tier F1)
Write-Host "`nStep 3: Creating App Service Plan (Free F1)..." -ForegroundColor Cyan
az appservice plan create `
  --name $APP_SERVICE_PLAN `
  --resource-group $RESOURCE_GROUP `
  --sku F1 `
  --is-linux 2>$null

# 4. Create Web App
Write-Host "`nStep 4: Creating Web App..." -ForegroundColor Cyan
az webapp create `
  --name $WEB_APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --plan $APP_SERVICE_PLAN `
  --runtime "DOTNET:8.0"

# 5. Enable HTTPS only
Write-Host "`nStep 5: Configuring HTTPS..." -ForegroundColor Cyan
az webapp update --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --https-only true

# 6. Configure application settings
Write-Host "`nStep 6: Configuring application settings..." -ForegroundColor Cyan
Write-Host "NOTE: Setting basic configuration. You need to add:" -ForegroundColor Yellow
Write-Host "  - Database connection string" -ForegroundColor Yellow
Write-Host "  - IoT Hub connection strings" -ForegroundColor Yellow
Write-Host "  Configure these in Azure Portal after deployment" -ForegroundColor Yellow

az webapp config appsettings set `
  --name $WEB_APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --settings `
    ASPNETCORE_ENVIRONMENT="Production" `
    JwtSettings__Issuer="IoTProjectAPI" `
    JwtSettings__Audience="IoTProjectClient" `
    JwtSettings__ExpirationDays="7"

# 7. Build and publish
Write-Host "`nStep 7: Building application..." -ForegroundColor Cyan
Set-Location IoTProject.API
dotnet publish -c Release -o ./publish

# 8. Create deployment package
Write-Host "`nStep 8: Creating deployment package..." -ForegroundColor Cyan
Set-Location publish
Compress-Archive -Path * -DestinationPath ../deploy.zip -Force
Set-Location ..

# 9. Deploy to Azure
Write-Host "`nStep 9: Deploying to Azure (this may take a few minutes)..." -ForegroundColor Cyan
az webapp deploy `
  --name $WEB_APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --src-path deploy.zip `
  --type zip `
  --async true

# 10. Wait and restart
Write-Host "`nStep 10: Waiting for deployment..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your API is available at:" -ForegroundColor Yellow
Write-Host "https://$WEB_APP_NAME.azurewebsites.net" -ForegroundColor White
Write-Host ""
Write-Host "Swagger UI:" -ForegroundColor Yellow
Write-Host "https://$WEB_APP_NAME.azurewebsites.net/swagger" -ForegroundColor White
Write-Host ""
Write-Host "Share this URL with your team!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Go to Azure Portal: https://portal.azure.com"
Write-Host "2. Navigate to App Service > $WEB_APP_NAME > Configuration"
Write-Host "3. Add Application Settings:"
Write-Host "   - ConnectionStrings__DefaultConnection = (your SQL connection string)"
Write-Host "   - JwtSettings__SecretKey = (generate random 32+ char string)"
Write-Host "   - AzureIoTHub__ConnectionString = (from IoT Hub)"
Write-Host "   - AzureIoTHub__EventHubConnectionString = (from IoT Hub)"
Write-Host "4. Click Save and Restart"
Write-Host ""
Write-Host "Test deployment:" -ForegroundColor Yellow
Write-Host "curl https://$WEB_APP_NAME.azurewebsites.net/health" -ForegroundColor White
Write-Host ""

# Save URL to file for easy reference
$WEB_APP_NAME | Out-File -FilePath "azure-url.txt" -Encoding UTF8
Write-Host "URL saved to: azure-url.txt" -ForegroundColor Green



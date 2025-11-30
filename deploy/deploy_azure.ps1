# Smart Brewery IoT - Azure Deployment Script
# Run this script to deploy the complete infrastructure to Azure

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "smart-brewery-rg",
    
    [Parameter(Mandatory=$true)]
    [string]$Location = "westeurope",
    
    [Parameter(Mandatory=$true)]
    [string]$AppName = "smart-brewery-api",
    
    [Parameter(Mandatory=$true)]
    [string]$SqlAdminPassword
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery IoT - Azure Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Login check
Write-Host "`n[1/8] Checking Azure login..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Please login to Azure..." -ForegroundColor Yellow
    az login
}
Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green

# Create Resource Group
Write-Host "`n[2/8] Creating Resource Group..." -ForegroundColor Yellow
az group create `
    --name $ResourceGroupName `
    --location $Location `
    --output none
Write-Host "Resource Group created: $ResourceGroupName" -ForegroundColor Green

# Create App Service Plan
Write-Host "`n[3/8] Creating App Service Plan (B1 - Basic)..." -ForegroundColor Yellow
az appservice plan create `
    --name "$AppName-plan" `
    --resource-group $ResourceGroupName `
    --sku B1 `
    --is-linux `
    --output none
Write-Host "App Service Plan created" -ForegroundColor Green

# Create Web App
Write-Host "`n[4/8] Creating Web App..." -ForegroundColor Yellow
az webapp create `
    --name $AppName `
    --resource-group $ResourceGroupName `
    --plan "$AppName-plan" `
    --runtime "PYTHON:3.11" `
    --output none
Write-Host "Web App created: $AppName.azurewebsites.net" -ForegroundColor Green

# Create SQL Server
Write-Host "`n[5/8] Creating Azure SQL Server..." -ForegroundColor Yellow
$sqlServerName = "$AppName-sql"
az sql server create `
    --name $sqlServerName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --admin-user "sqladmin" `
    --admin-password $SqlAdminPassword `
    --output none

# Allow Azure services to access SQL
az sql server firewall-rule create `
    --resource-group $ResourceGroupName `
    --server $sqlServerName `
    --name "AllowAzureServices" `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 0.0.0.0 `
    --output none
Write-Host "SQL Server created: $sqlServerName.database.windows.net" -ForegroundColor Green

# Create SQL Database
Write-Host "`n[6/8] Creating SQL Database (Basic tier)..." -ForegroundColor Yellow
az sql db create `
    --name "smartbrewery" `
    --server $sqlServerName `
    --resource-group $ResourceGroupName `
    --service-objective Basic `
    --output none
Write-Host "SQL Database created: smartbrewery" -ForegroundColor Green

# Create IoT Hub
Write-Host "`n[7/8] Creating IoT Hub (F1 - Free tier)..." -ForegroundColor Yellow
$iotHubName = "$AppName-iothub"
az iot hub create `
    --name $iotHubName `
    --resource-group $ResourceGroupName `
    --sku F1 `
    --partition-count 2 `
    --output none
Write-Host "IoT Hub created: $iotHubName.azure-devices.net" -ForegroundColor Green

# Register IoT Device for Raspberry Pi
Write-Host "Registering IoT Device: raspberry-pi-brewery..." -ForegroundColor Yellow
az iot hub device-identity create `
    --hub-name $iotHubName `
    --device-id "raspberry-pi-brewery" `
    --output none

# Get device connection string
$deviceConnectionString = az iot hub device-identity connection-string show `
    --hub-name $iotHubName `
    --device-id "raspberry-pi-brewery" `
    --query connectionString -o tsv

# Configure App Settings
Write-Host "`n[8/8] Configuring App Settings..." -ForegroundColor Yellow
$dbConnectionString = "mssql+pyodbc://sqladmin:$SqlAdminPassword@$sqlServerName.database.windows.net/smartbrewery?driver=ODBC+Driver+18+for+SQL+Server"
$secretKey = [System.Guid]::NewGuid().ToString() + [System.Guid]::NewGuid().ToString()

az webapp config appsettings set `
    --name $AppName `
    --resource-group $ResourceGroupName `
    --settings `
        DATABASE_URL="$dbConnectionString" `
        SECRET_KEY="$secretKey" `
        IOT_HUB_HOSTNAME="$iotHubName.azure-devices.net" `
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" `
    --output none

# Set startup command
az webapp config set `
    --name $AppName `
    --resource-group $ResourceGroupName `
    --startup-file "gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:8000" `
    --output none

Write-Host "App Settings configured" -ForegroundColor Green

# Output summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n--- API Server (Mobile Team) ---" -ForegroundColor Yellow
Write-Host "URL: https://$AppName.azurewebsites.net" -ForegroundColor White
Write-Host "Docs: https://$AppName.azurewebsites.net/docs" -ForegroundColor White

Write-Host "`n--- IoT Hub (Hardware Team) ---" -ForegroundColor Yellow
Write-Host "Hostname: $iotHubName.azure-devices.net" -ForegroundColor White
Write-Host "Port: 8883 (MQTT over TLS)" -ForegroundColor White
Write-Host "Device ID: raspberry-pi-brewery" -ForegroundColor White
Write-Host "`nDevice Connection String:" -ForegroundColor Yellow
Write-Host $deviceConnectionString -ForegroundColor Cyan

Write-Host "`n--- SQL Database ---" -ForegroundColor Yellow
Write-Host "Server: $sqlServerName.database.windows.net" -ForegroundColor White
Write-Host "Database: smartbrewery" -ForegroundColor White
Write-Host "User: sqladmin" -ForegroundColor White

Write-Host "`n--- Monthly Cost Estimate ---" -ForegroundColor Yellow
Write-Host "App Service B1: ~`$13" -ForegroundColor White
Write-Host "SQL Database Basic: ~`$5" -ForegroundColor White
Write-Host "IoT Hub F1: FREE" -ForegroundColor White
Write-Host "Total: ~`$18/month" -ForegroundColor Green

Write-Host "`n--- Next Steps ---" -ForegroundColor Yellow
Write-Host "1. Deploy code: .\deploy_code.ps1 -AppName $AppName -ResourceGroupName $ResourceGroupName" -ForegroundColor White
Write-Host "2. Share IoT connection string with Hardware Team" -ForegroundColor White
Write-Host "3. Update Postman base_url to https://$AppName.azurewebsites.net" -ForegroundColor White

# Save connection info to file
$outputFile = "azure_deployment_info.txt"
@"
Smart Brewery IoT - Azure Deployment Info
==========================================
Generated: $(Get-Date)

API SERVER (Mobile Team)
------------------------
URL: https://$AppName.azurewebsites.net
API Docs: https://$AppName.azurewebsites.net/docs
Health Check: https://$AppName.azurewebsites.net/health

IOT HUB (Hardware Team)
-----------------------
Hostname: $iotHubName.azure-devices.net
Port: 8883 (MQTT over TLS)
Device ID: raspberry-pi-brewery
Connection String: $deviceConnectionString

SQL DATABASE
------------
Server: $sqlServerName.database.windows.net
Database: smartbrewery
Username: sqladmin
Password: [stored in Azure App Settings]

RESOURCE GROUP
--------------
Name: $ResourceGroupName
Location: $Location
"@ | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`nDeployment info saved to: $outputFile" -ForegroundColor Green


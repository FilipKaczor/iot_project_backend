# Smart Brewery IoT - IoT Hub to Function App Routing
# This script sets up message routing from IoT Hub to process sensor data

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "smart-brewery-rg",
    
    [Parameter(Mandatory=$true)]
    [string]$AppName = "smart-brewery-api"
)

$ErrorActionPreference = "Stop"
$iotHubName = "$AppName-iothub"
$functionAppName = "$AppName-functions"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery IoT - IoT Hub Routing Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Create Function App for processing IoT messages
Write-Host "`n[1/3] Creating Function App..." -ForegroundColor Yellow

# Create storage account for Function App
$storageAccountName = ($AppName -replace "-", "").ToLower() + "storage"
if ($storageAccountName.Length -gt 24) {
    $storageAccountName = $storageAccountName.Substring(0, 24)
}

az storage account create `
    --name $storageAccountName `
    --resource-group $ResourceGroupName `
    --location westeurope `
    --sku Standard_LRS `
    --output none

# Create Function App
az functionapp create `
    --name $functionAppName `
    --resource-group $ResourceGroupName `
    --storage-account $storageAccountName `
    --consumption-plan-location westeurope `
    --runtime python `
    --runtime-version 3.11 `
    --functions-version 4 `
    --output none

Write-Host "Function App created: $functionAppName" -ForegroundColor Green

# Get IoT Hub connection string
Write-Host "`n[2/3] Configuring IoT Hub connection..." -ForegroundColor Yellow
$iotHubConnectionString = az iot hub connection-string show `
    --hub-name $iotHubName `
    --policy-name iothubowner `
    --query connectionString -o tsv

# Configure Function App settings
$webAppSettings = az webapp config appsettings list `
    --name $AppName `
    --resource-group $ResourceGroupName | ConvertFrom-Json

$dbUrl = ($webAppSettings | Where-Object { $_.name -eq "DATABASE_URL" }).value
$secretKey = ($webAppSettings | Where-Object { $_.name -eq "SECRET_KEY" }).value

az functionapp config appsettings set `
    --name $functionAppName `
    --resource-group $ResourceGroupName `
    --settings `
        IoTHubConnection="$iotHubConnectionString" `
        DATABASE_URL="$dbUrl" `
        SECRET_KEY="$secretKey" `
    --output none

Write-Host "Function App configured" -ForegroundColor Green

Write-Host "`n[3/3] Setting up Event Hub consumer group..." -ForegroundColor Yellow
az iot hub consumer-group create `
    --hub-name $iotHubName `
    --name "functionapp" `
    --output none

Write-Host "Consumer group created" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "IOT HUB ROUTING SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nFunction App: $functionAppName" -ForegroundColor Cyan
Write-Host "`nNext: Deploy the Azure Function code to process IoT messages" -ForegroundColor Yellow


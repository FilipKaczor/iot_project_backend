# Smart Brewery IoT - Code Deployment Script
# Run this after deploy_azure.ps1 to deploy the application code

param(
    [Parameter(Mandatory=$true)]
    [string]$AppName = "smart-brewery-api",
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "smart-brewery-rg"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery IoT - Code Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get project root (parent of deploy folder)
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "`n[1/4] Preparing deployment package..." -ForegroundColor Yellow

# Create deployment folder
$deployFolder = ".\deploy_package"
if (Test-Path $deployFolder) {
    Remove-Item $deployFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $deployFolder | Out-Null

# Copy application files
Copy-Item -Path ".\app" -Destination "$deployFolder\app" -Recurse
Copy-Item -Path ".\requirements.txt" -Destination "$deployFolder\"

# Create startup.txt for Azure
@"
gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:8000
"@ | Out-File -FilePath "$deployFolder\startup.txt" -Encoding UTF8 -NoNewline

Write-Host "Deployment package prepared" -ForegroundColor Green

Write-Host "`n[2/4] Creating ZIP archive..." -ForegroundColor Yellow
$zipFile = ".\deploy_package.zip"
if (Test-Path $zipFile) {
    Remove-Item $zipFile -Force
}
Compress-Archive -Path "$deployFolder\*" -DestinationPath $zipFile
Write-Host "ZIP archive created: $zipFile" -ForegroundColor Green

Write-Host "`n[3/4] Deploying to Azure App Service..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --name $AppName `
    --resource-group $ResourceGroupName `
    --src $zipFile

Write-Host "Code deployed successfully!" -ForegroundColor Green

Write-Host "`n[4/4] Restarting application..." -ForegroundColor Yellow
az webapp restart `
    --name $AppName `
    --resource-group $ResourceGroupName

Write-Host "Application restarted" -ForegroundColor Green

# Cleanup
Remove-Item $deployFolder -Recurse -Force
Remove-Item $zipFile -Force

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nAPI URL: https://$AppName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "API Docs: https://$AppName.azurewebsites.net/docs" -ForegroundColor Cyan

Write-Host "`nTesting health endpoint..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
try {
    $response = Invoke-WebRequest -Uri "https://$AppName.azurewebsites.net/health" -UseBasicParsing
    Write-Host "Health check: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "Note: App may take 1-2 minutes to start. Check manually." -ForegroundColor Yellow
}


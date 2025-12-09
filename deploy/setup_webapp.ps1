# Setup Azure Web App for Smart Brewery IoT Server
# This script creates:
# 1. Resource Group
# 2. Azure SQL Database
# 3. Azure App Service Plan
# 4. Azure Web App (Linux)

param(
    [string]$ResourceGroupName = "smart-brewery-rg-webapp",
    [string]$Location = "West Europe",
    [string]$SqlServerName = "smart-brewery-sql-webapp",
    [string]$SqlDatabaseName = "smartbrewerydb",
    [string]$AppServicePlanName = "smart-brewery-plan",
    [string]$WebAppName = "smart-brewery-webapp",
    [string]$SqlAdminUser = "sqladmin",
    [string]$SqlAdminPassword = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery - Web App Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if logged in
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Please login to Azure first: az login" -ForegroundColor Red
    exit 1
}

# Generate SQL password if not provided
if ([string]::IsNullOrEmpty($SqlAdminPassword)) {
    $SqlAdminPassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object {[char]$_})
    Write-Host "Generated SQL password: $SqlAdminPassword" -ForegroundColor Yellow
    Write-Host "SAVE THIS PASSWORD!" -ForegroundColor Red
}

# 1. Create Resource Group
Write-Host "`n[1/5] Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location | Out-Null
Write-Host "Resource Group created" -ForegroundColor Green

# 2. Create Azure SQL Server
Write-Host "`n[2/5] Creating Azure SQL Server..." -ForegroundColor Yellow
$sqlServer = az sql server create `
    --name $SqlServerName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --admin-user $SqlAdminUser `
    --admin-password $SqlAdminPassword `
    --output json | ConvertFrom-Json

Write-Host "[OK] SQL Server created: $($sqlServer.fullyQualifiedDomainName)" -ForegroundColor Green

# Configure firewall to allow Azure services
az sql server firewall-rule create `
    --resource-group $ResourceGroupName `
    --server $SqlServerName `
    --name "AllowAzureServices" `
    --start-ip-address "0.0.0.0" `
    --end-ip-address "0.0.0.0" | Out-Null

Write-Host "[OK] Firewall configured" -ForegroundColor Green

# 3. Create SQL Database
Write-Host "`n[3/5] Creating SQL Database..." -ForegroundColor Yellow
az sql db create `
    --resource-group $ResourceGroupName `
    --server $SqlServerName `
    --name $SqlDatabaseName `
    --service-objective "S0" `
    --backup-storage-redundancy "Local" | Out-Null

Write-Host "[OK] SQL Database created" -ForegroundColor Green

# 4. Create App Service Plan
Write-Host "`n[4/5] Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create `
    --name $AppServicePlanName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku B1 `
    --is-linux | Out-Null

Write-Host "[OK] App Service Plan created" -ForegroundColor Green

# 5. Create Web App
Write-Host "`n[5/5] Creating Web App..." -ForegroundColor Yellow
az webapp create `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --plan $AppServicePlanName `
    --runtime "PYTHON:3.11" | Out-Null

Write-Host "[OK] Web App created" -ForegroundColor Green

# Configure Web App
Write-Host "`nConfiguring Web App..." -ForegroundColor Yellow

# Set startup command
az webapp config set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --startup-file "startup.sh" | Out-Null

# Enable HTTP/1.1 (default, but explicit)
az webapp config set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --http20-enabled false | Out-Null

Write-Host "[OK] Web App configured" -ForegroundColor Green

# Build connection string
Add-Type -AssemblyName System.Web
$encodedPassword = [System.Web.HttpUtility]::UrlEncode($SqlAdminPassword)
$connectionString = "mssql+pymssql://${SqlAdminUser}:${encodedPassword}@${sqlServer.fullyQualifiedDomainName}:1433/${SqlDatabaseName}"

# Set environment variables
Write-Host "`nSetting environment variables..." -ForegroundColor Yellow
az webapp config appsettings set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --settings `
        "DATABASE_URL=$connectionString" `
        "SCM_DO_BUILD_DURING_DEPLOYMENT=true" `
        "ENABLE_ORYX_BUILD=true" | Out-Null

Write-Host "[OK] Environment variables set" -ForegroundColor Green

# Save secrets to file
$secretsFile = "secrets.txt"
$secretsContent = @"
# Smart Brewery - Secrets (Web App)
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# DO NOT COMMIT THIS FILE TO GIT!

# SQL Database
SQL_SERVER_NAME=$SqlServerName
SQL_DATABASE_NAME=$SqlDatabaseName
SQL_ADMIN_USER=$SqlAdminUser
SQL_ADMIN_PASSWORD=$SqlAdminPassword

# Azure Resources
RESOURCE_GROUP=$ResourceGroupName
WEB_APP_NAME=$WebAppName
APP_SERVICE_PLAN=$AppServicePlanName
SQL_SERVER_FQDN=$($sqlServer.fullyQualifiedDomainName)

# Web App URL
WEB_APP_URL=https://$WebAppName.azurewebsites.net
"@

$secretsContent | Out-File -FilePath $secretsFile -Encoding UTF8
Write-Host "[OK] Secrets saved to: $secretsFile" -ForegroundColor Green

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nConfiguration Details:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  SQL Server: $($sqlServer.fullyQualifiedDomainName)" -ForegroundColor White
Write-Host "  SQL Database: $SqlDatabaseName" -ForegroundColor White
Write-Host "  SQL Admin User: $SqlAdminUser" -ForegroundColor White
Write-Host "  SQL Admin Password: $SqlAdminPassword" -ForegroundColor Red
Write-Host "  Web App: https://$WebAppName.azurewebsites.net" -ForegroundColor White
Write-Host "`nSecrets saved to: $secretsFile" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Check secrets.txt file (password is saved there)" -ForegroundColor White
Write-Host "  2. Run: .\deploy\deploy_webapp.ps1" -ForegroundColor White


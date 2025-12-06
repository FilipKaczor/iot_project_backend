# Setup Azure Resources for Smart Brewery IoT Server
# This script creates:
# 1. Resource Group
# 2. Azure SQL Database
# 3. Azure Container Registry
# 4. Azure Container App Environment
# 5. Azure Container App

param(
    [string]$ResourceGroupName = "smart-brewery-rg",
    [string]$Location = "West Europe",
    [string]$SqlServerName = "smart-brewery-sql",
    [string]$SqlDatabaseName = "smartbrewerydb",
    [string]$AcrName = "smartbreweryacr",
    [string]$ContainerAppName = "smart-brewery",
    [string]$SqlAdminUser = "sqladmin",
    [string]$SqlAdminPassword = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery - Azure Setup" -ForegroundColor Cyan
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

# 4. Create Azure Container Registry
Write-Host "`n[4/5] Creating Azure Container Registry..." -ForegroundColor Yellow
az acr create `
    --resource-group $ResourceGroupName `
    --name $AcrName `
    --sku Basic `
    --admin-enabled true | Out-Null

$acrLoginServer = az acr show --name $AcrName --resource-group $ResourceGroupName --query loginServer -o tsv
Write-Host "[OK] ACR created: $acrLoginServer" -ForegroundColor Green

# 5. Create Container App Environment
Write-Host "`n[5/5] Creating Container App Environment..." -ForegroundColor Yellow
az containerapp env create `
    --name "$ContainerAppName-env" `
    --resource-group $ResourceGroupName `
    --location $Location | Out-Null

Write-Host "[OK] Container App Environment created" -ForegroundColor Green

# Save secrets to file
$secretsFile = "secrets.txt"
$secretsContent = @"
# Smart Brewery - Secrets
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# DO NOT COMMIT THIS FILE TO GIT!

# SQL Database
SQL_SERVER_NAME=$SqlServerName
SQL_DATABASE_NAME=$SqlDatabaseName
SQL_ADMIN_USER=$SqlAdminUser
SQL_ADMIN_PASSWORD=$SqlAdminPassword

# Azure Resources
RESOURCE_GROUP=$ResourceGroupName
ACR_NAME=$AcrName
CONTAINER_APP_NAME=$ContainerAppName
SQL_SERVER_FQDN=$($sqlServer.fullyQualifiedDomainName)
"@

$secretsContent | Out-File -FilePath $secretsFile -Encoding UTF8
Write-Host "[OK] Secrets saved to: $secretsFile" -ForegroundColor Green
Write-Host "  (This file is in .gitignore and will NOT be committed)" -ForegroundColor Gray

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
Write-Host "  ACR: $acrLoginServer" -ForegroundColor White
Write-Host "`nSecrets saved to: $secretsFile" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Check secrets.txt file (password is saved there)" -ForegroundColor White
Write-Host "  2. Run: .\deploy\build_and_deploy.ps1" -ForegroundColor White


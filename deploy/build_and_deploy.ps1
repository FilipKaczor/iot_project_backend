# Build and Deploy Smart Brewery IoT Server
param(
    [string]$ResourceGroupName = "smart-brewery-rg",
    [string]$AcrName = "smartbreweryacr",
    [string]$ContainerAppName = "smart-brewery",
    [string]$ImageTag = "latest",
    [string]$SqlServerName = "smart-brewery-sql",
    [string]$SqlDatabaseName = "smartbrewerydb",
    [string]$SqlAdminUser = "sqladmin",
    [string]$SqlAdminPassword = "",
    [string]$SecretKey = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery - Build & Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Try to load from secrets.txt
$secretsFile = "secrets.txt"
if (Test-Path $secretsFile) {
    Write-Host "Loading secrets from $secretsFile..." -ForegroundColor Gray
    $secrets = Get-Content $secretsFile | Where-Object { $_ -match "^[^#].*=" } | ForEach-Object {
        $parts = $_ -split "=", 2
        @{Key = $parts[0].Trim(); Value = $parts[1].Trim()}
    }
    $secretsHash = @{}
    $secrets | ForEach-Object { $secretsHash[$_.Key] = $_.Value }
    
    if ([string]::IsNullOrEmpty($SqlAdminPassword) -and $secretsHash.ContainsKey("SQL_ADMIN_PASSWORD")) {
        $SqlAdminPassword = $secretsHash["SQL_ADMIN_PASSWORD"]
        Write-Host "[OK] SQL password loaded from secrets.txt" -ForegroundColor Green
    }
    if ([string]::IsNullOrEmpty($SecretKey) -and $secretsHash.ContainsKey("SECRET_KEY")) {
        $SecretKey = $secretsHash["SECRET_KEY"]
        Write-Host "[OK] SECRET_KEY loaded from secrets.txt" -ForegroundColor Green
    }
    if ([string]::IsNullOrEmpty($SqlServerName) -and $secretsHash.ContainsKey("SQL_SERVER_NAME")) {
        $SqlServerName = $secretsHash["SQL_SERVER_NAME"]
    }
    if ([string]::IsNullOrEmpty($SqlDatabaseName) -and $secretsHash.ContainsKey("SQL_DATABASE_NAME")) {
        $SqlDatabaseName = $secretsHash["SQL_DATABASE_NAME"]
    }
    if ([string]::IsNullOrEmpty($SqlAdminUser) -and $secretsHash.ContainsKey("SQL_ADMIN_USER")) {
        $SqlAdminUser = $secretsHash["SQL_ADMIN_USER"]
    }
}

# Check if SQL password is provided
if ([string]::IsNullOrEmpty($SqlAdminPassword)) {
    Write-Host "Please provide SQL admin password:" -ForegroundColor Yellow
    $securePassword = Read-Host -AsSecureString
    $SqlAdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
}

# Generate Secret Key if not provided
if ([string]::IsNullOrEmpty($SecretKey)) {
    $SecretKey = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    Write-Host "Generated SECRET_KEY: $SecretKey" -ForegroundColor Yellow
    
    # Save to secrets.txt if it exists
    if (Test-Path $secretsFile) {
        $content = Get-Content $secretsFile -Raw
        if ($content -notmatch "SECRET_KEY=") {
            Add-Content -Path $secretsFile -Value "`n# JWT Secret Key`nSECRET_KEY=$SecretKey"
            Write-Host "[OK] SECRET_KEY saved to secrets.txt" -ForegroundColor Green
        }
    }
}

# Get SQL Server FQDN
$sqlServerFqdn = az sql server show `
    --resource-group $ResourceGroupName `
    --name $SqlServerName `
    --query fullyQualifiedDomainName -o tsv

if (-not $sqlServerFqdn) {
    Write-Host "Error: SQL Server not found. Run setup_azure.ps1 first." -ForegroundColor Red
    exit 1
}

# Build connection string (URL encode password)
Add-Type -AssemblyName System.Web
$encodedPassword = [System.Web.HttpUtility]::UrlEncode($SqlAdminPassword)
# Build connection string with proper encoding
$connectionString = "mssql+pyodbc://${SqlAdminUser}:${encodedPassword}@${sqlServerFqdn}:1433/${SqlDatabaseName}?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=yes&TrustServerCertificate=no"

Write-Host "`n[1/4] Building Docker image..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

# Build with stderr redirected to avoid encoding issues with Azure CLI logs
$ErrorActionPreference = "SilentlyContinue"
$buildResult = az acr build `
    --registry $AcrName `
    --image "$ContainerAppName`:$ImageTag" `
    --file Dockerfile . `
    --no-logs 2>$null

$ErrorActionPreference = "Continue"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed (exit code: $LASTEXITCODE)" -ForegroundColor Red
    Write-Host "Check build logs in Azure Portal:" -ForegroundColor Yellow
    Write-Host "  https://portal.azure.com -> Container Registries -> $AcrName -> Services -> Builds" -ForegroundColor White
    exit 1
}
Write-Host "[OK] Image built successfully" -ForegroundColor Green

# Check if Container App exists
$appExists = az containerapp show `
    --name $ContainerAppName `
    --resource-group $ResourceGroupName `
    --query name -o tsv 2>$null

if ($appExists) {
    Write-Host "`n[2/4] Updating Container App..." -ForegroundColor Yellow
    az containerapp update `
        --name $ContainerAppName `
        --resource-group $ResourceGroupName `
        --image "$AcrName.azurecr.io/$ContainerAppName`:$ImageTag" | Out-Null
} else {
    Write-Host "`n[2/4] Creating Container App..." -ForegroundColor Yellow
    
    # Get ACR credentials
    $acrUsername = az acr credential show --name $AcrName --query username -o tsv
    $acrPassword = az acr credential show --name $AcrName --query passwords[0].value -o tsv
    
    # Create Container App
    az containerapp create `
        --name $ContainerAppName `
        --resource-group $ResourceGroupName `
        --environment "$ContainerAppName-env" `
        --image "$AcrName.azurecr.io/$ContainerAppName`:$ImageTag" `
        --registry-server "$AcrName.azurecr.io" `
        --registry-username $acrUsername `
        --registry-password $acrPassword `
        --target-port 8000 `
        --ingress external `
        --cpu 0.5 `
        --memory 1.0Gi | Out-Null
}

Write-Host "[OK] Container App configured" -ForegroundColor Green

# Set environment variables
Write-Host "`n[3/4] Setting environment variables..." -ForegroundColor Yellow
# Use --set-env-vars with proper escaping - each variable separately
# Connection string needs to be in single quotes to avoid PowerShell parsing issues
$envVars = @(
    "DATABASE_URL='$connectionString'",
    "SECRET_KEY=$SecretKey",
    "ACCESS_TOKEN_EXPIRE_MINUTES=30"
) -join " "

az containerapp update `
    --name $ContainerAppName `
    --resource-group $ResourceGroupName `
    --set-env-vars $envVars | Out-Null

Write-Host "[OK] Environment variables set" -ForegroundColor Green

# Get app URL
Write-Host "`n[4/4] Getting app URL..." -ForegroundColor Yellow
$appUrl = az containerapp show `
    --name $ContainerAppName `
    --resource-group $ResourceGroupName `
    --query properties.configuration.ingress.fqdn -o tsv

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nApp URL: https://$appUrl" -ForegroundColor Green
Write-Host "`nAPI Documentation:" -ForegroundColor Yellow
Write-Host "  https://$appUrl/docs" -ForegroundColor White
Write-Host "`nTest endpoint:" -ForegroundColor Yellow
Write-Host "  curl https://$appUrl/health" -ForegroundColor White
Write-Host "`nSave these values:" -ForegroundColor Yellow
Write-Host "  SECRET_KEY: $SecretKey" -ForegroundColor Red
Write-Host "  SQL Password: [your password]" -ForegroundColor Red


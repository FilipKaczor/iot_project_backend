# Deploy Smart Brewery IoT Server to Azure Web App
param(
    [string]$ResourceGroupName = "smart-brewery-rg-webapp",
    [string]$WebAppName = "smart-brewery-webapp",
    [string]$SecretKey = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery - Web App Deployment" -ForegroundColor Cyan
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
    
    if ([string]::IsNullOrEmpty($SecretKey) -and $secretsHash.ContainsKey("SECRET_KEY")) {
        $SecretKey = $secretsHash["SECRET_KEY"]
        Write-Host "[OK] SECRET_KEY loaded from secrets.txt" -ForegroundColor Green
    }
    if ([string]::IsNullOrEmpty($ResourceGroupName) -and $secretsHash.ContainsKey("RESOURCE_GROUP")) {
        $ResourceGroupName = $secretsHash["RESOURCE_GROUP"]
    }
    if ([string]::IsNullOrEmpty($WebAppName) -and $secretsHash.ContainsKey("WEB_APP_NAME")) {
        $WebAppName = $secretsHash["WEB_APP_NAME"]
    }
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

# Set SECRET_KEY environment variable
Write-Host "`n[1/3] Setting environment variables..." -ForegroundColor Yellow
az webapp config appsettings set `
    --name $WebAppName `
    --resource-group $ResourceGroupName `
    --settings "SECRET_KEY=$SecretKey" "ACCESS_TOKEN_EXPIRE_MINUTES=30" | Out-Null

Write-Host "[OK] Environment variables set" -ForegroundColor Green

# Create deployment package
Write-Host "`n[2/3] Creating deployment package..." -ForegroundColor Yellow

# Create temp directory
$tempDir = "deploy_temp"
if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy files
Copy-Item -Path "app" -Destination "$tempDir/app" -Recurse
Copy-Item -Path "main.py" -Destination "$tempDir/main.py"
Copy-Item -Path "requirements.txt" -Destination "$tempDir/requirements.txt"
Copy-Item -Path "startup.sh" -Destination "$tempDir/startup.sh"

# Create .deployment file for Azure
$deploymentContent = @"
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
"@
$deploymentContent | Out-File -FilePath "$tempDir/.deployment" -Encoding UTF8

# Create zip
$zipFile = "deploy.zip"
if (Test-Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}

Write-Host "Compressing files..." -ForegroundColor Gray
Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFile -Force

Write-Host "[OK] Deployment package created: $zipFile" -ForegroundColor Green

# Deploy to Azure
Write-Host "`n[3/3] Deploying to Azure Web App..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

az webapp deployment source config-zip `
    --resource-group $ResourceGroupName `
    --name $WebAppName `
    --src $zipFile | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Deployment successful" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Deployment failed" -ForegroundColor Red
    exit 1
}

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force
Remove-Item -Path $zipFile -Force

# Get app URL
$appUrl = "https://$WebAppName.azurewebsites.net"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nWeb App URL: $appUrl" -ForegroundColor Green
Write-Host "`nAPI Documentation:" -ForegroundColor Yellow
Write-Host "  $appUrl/docs" -ForegroundColor White
Write-Host "`nTest endpoint:" -ForegroundColor Yellow
Write-Host "  curl $appUrl/health" -ForegroundColor White
Write-Host "`nSave these values:" -ForegroundColor Yellow
Write-Host "  SECRET_KEY: $SecretKey" -ForegroundColor Red
Write-Host "  SQL Password: [check secrets.txt]" -ForegroundColor Red


# Przygotuj deployment package dla Azure Web App
# Uruchom ten skrypt przed ręcznym deploymentem przez portal

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Preparing Deployment Package" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Czyść stare pliki
Write-Host "`n[1/4] Cleaning old files..." -ForegroundColor Yellow
if (Test-Path "deploy_package") {
    Remove-Item -Path "deploy_package" -Recurse -Force
}
if (Test-Path "deploy_package.zip") {
    Remove-Item -Path "deploy_package.zip" -Force
}

# Utwórz folder
Write-Host "`n[2/4] Creating package folder..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "deploy_package" | Out-Null

# Skopiuj pliki
Write-Host "`n[3/4] Copying files..." -ForegroundColor Yellow
Copy-Item -Path "app" -Destination "deploy_package\app" -Recurse
Copy-Item -Path "main.py" -Destination "deploy_package\main.py"
Copy-Item -Path "requirements.txt" -Destination "deploy_package\requirements.txt"

Write-Host "  [OK] app/" -ForegroundColor Green
Write-Host "  [OK] main.py" -ForegroundColor Green
Write-Host "  [OK] requirements.txt" -ForegroundColor Green

# Utwórz .deployment file
$deploymentContent = @"
[config]
SCM_DO_BUILD_DURING_DEPLOYMENT=true
"@
$deploymentContent | Out-File -FilePath "deploy_package\.deployment" -Encoding UTF8
Write-Host "  [OK] .deployment" -ForegroundColor Green

# Sprawdź co jest w folderze
Write-Host "`n[4/4] Package contents:" -ForegroundColor Yellow
Get-ChildItem -Path "deploy_package" -Recurse | Select-Object FullName | Format-Table

# Stwórz ZIP
Write-Host "`nCreating ZIP file..." -ForegroundColor Yellow
Compress-Archive -Path "deploy_package\*" -DestinationPath "deploy_package.zip" -Force

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Package Ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nCreated files:" -ForegroundColor Yellow
Write-Host "  deploy_package/        - Unzipped files" -ForegroundColor White
Write-Host "  deploy_package.zip     - Ready for upload" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. Open AZURE_PORTAL_SETUP.md" -ForegroundColor White
Write-Host "  2. Follow instructions step by step" -ForegroundColor White
Write-Host "  3. Upload deploy_package.zip in KROK 5 or 6" -ForegroundColor White

Write-Host "`nOr use Azure CLI:" -ForegroundColor Yellow
Write-Host '  az webapp deploy --resource-group smart-brewery-rg --name smart-brewery-app --src-path deploy_package.zip --type zip' -ForegroundColor Gray

Write-Host ""


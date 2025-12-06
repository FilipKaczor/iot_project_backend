# Quick Deploy - All-in-one script
# This script does everything: setup + build + deploy

param(
    [string]$ResourceGroupName = "smart-brewery-rg",
    [string]$Location = "West Europe",
    [string]$SqlServerName = "smart-brewery-sql",
    [string]$SqlDatabaseName = "smartbrewerydb",
    [string]$AcrName = "smartbreweryacr",
    [string]$ContainerAppName = "smart-brewery",
    [string]$SqlAdminUser = "sqladmin",
    [string]$SqlAdminPassword = "",
    [string]$SecretKey = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery - Quick Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if resource group exists
$rgExists = az group show --name $ResourceGroupName --query name -o tsv 2>$null

if (-not $rgExists) {
    Write-Host "`nRunning setup..." -ForegroundColor Yellow
    & ".\deploy\setup_azure.ps1" `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -SqlServerName $SqlServerName `
        -SqlDatabaseName $SqlDatabaseName `
        -AcrName $AcrName `
        -ContainerAppName $ContainerAppName `
        -SqlAdminUser $SqlAdminUser `
        -SqlAdminPassword $SqlAdminPassword
} else {
    Write-Host "`nResource group exists, skipping setup..." -ForegroundColor Yellow
}

# If password not provided, ask for it
if ([string]::IsNullOrEmpty($SqlAdminPassword)) {
    Write-Host "`nPlease provide SQL admin password:" -ForegroundColor Yellow
    $securePassword = Read-Host -AsSecureString
    $SqlAdminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    )
}

Write-Host "`nBuilding and deploying..." -ForegroundColor Yellow
& ".\deploy\build_and_deploy.ps1" `
    -ResourceGroupName $ResourceGroupName `
    -AcrName $AcrName `
    -ContainerAppName $ContainerAppName `
    -SqlServerName $SqlServerName `
    -SqlDatabaseName $SqlDatabaseName `
    -SqlAdminUser $SqlAdminUser `
    -SqlAdminPassword $SqlAdminPassword `
    -SecretKey $SecretKey

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "All done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan


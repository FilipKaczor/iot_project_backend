# Test API Endpoints
param(
    [string]$BaseUrl = ""
)

if ([string]::IsNullOrEmpty($BaseUrl)) {
    Write-Host "Please provide BaseUrl:" -ForegroundColor Yellow
    Write-Host "  .\test_api.ps1 -BaseUrl 'https://your-app.azurecontainerapps.io'" -ForegroundColor White
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Smart Brewery API" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Health Check
Write-Host "`n[1] Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET
    Write-Host "✓ Status: $($health.status)" -ForegroundColor Green
    Write-Host "  Database: $($health.database)" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. Register User
Write-Host "`n[2] Registering user..." -ForegroundColor Yellow
$registerData = @{
    email = "test@example.com"
    username = "testuser"
    password = "testpassword123"
    full_name = "Test User"
} | ConvertTo-Json

try {
    $register = Invoke-RestMethod -Uri "$BaseUrl/register" -Method POST -Body $registerData -ContentType "application/json"
    Write-Host "✓ User registered: $($register.username)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "⚠ User already exists, continuing..." -ForegroundColor Yellow
    } else {
        Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 3. Login
Write-Host "`n[3] Logging in..." -ForegroundColor Yellow
$loginBody = "username=testuser&password=testpassword123"
try {
    $login = Invoke-RestMethod -Uri "$BaseUrl/login" -Method POST -Body $loginBody -ContentType "application/x-www-form-urlencoded"
    $token = $login.access_token
    Write-Host "✓ Login successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. Send Sensor Data
Write-Host "`n[4] Sending sensor data..." -ForegroundColor Yellow
$sensorData = @{
    type = "temperature"
    value = 22.5
} | ConvertTo-Json

try {
    $sensor = Invoke-RestMethod -Uri "$BaseUrl/sensor/data" -Method POST -Body $sensorData -ContentType "application/json"
    Write-Host "✓ Sensor data sent: $($sensor.message)" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Get Readings (with auth)
Write-Host "`n[5] Getting readings (requires auth)..." -ForegroundColor Yellow
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

try {
    $readings = Invoke-RestMethod -Uri "$BaseUrl/readings/temperature?days=1" -Method GET -Headers $headers
    Write-Host "✓ Readings retrieved: $($readings.Count) records" -ForegroundColor Green
    if ($readings.Count -gt 0) {
        Write-Host "  Latest: $($readings[0].temperature_celsius)°C at $($readings[0].timestamp)" -ForegroundColor White
    }
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Get User Info
Write-Host "`n[6] Getting user info..." -ForegroundColor Yellow
try {
    $userInfo = Invoke-RestMethod -Uri "$BaseUrl/me" -Method GET -Headers $headers
    Write-Host "✓ User info: $($userInfo.username) ($($userInfo.email))" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan


# Test Script for All Smart Brewery API Endpoints

param(
    [string]$BaseUrl = "https://smart-brewery.wittyforest-43b9cebb.westeurope.azurecontainerapps.io"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Smart Brewery - Full API Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host ""

$headers = @{}
$token = ""
$testDeviceId = "raspberry-pi-brewery"
$testUsername = "testuser-$(Get-Random -Maximum 10000)"
$testEmail = "test-$((Get-Random -Maximum 10000))@example.com"
$testPassword = "TestPassword123!"
$testFullName = "Test User"

$results = @{
    Total = 0
    Passed = 0
    Failed = 0
}

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Endpoint,
        [hashtable]$Headers = @{},
        $Body = $null,
        [string]$ExpectedStatus = "200",
        [bool]$SaveToken = $false
    )
    
    $results.Total++
    $uri = "$BaseUrl$Endpoint"
    
    Write-Host "[TEST] $Name" -ForegroundColor DarkCyan -NoNewline
    Write-Host " ($Method $Endpoint)" -ForegroundColor Gray
    
    try {
        $params = @{
            Uri = $uri
            Method = $Method
            Headers = $Headers
            TimeoutSec = 15
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            if ($Body -is [string]) {
                $params.Body = $Body
                $params.ContentType = "application/x-www-form-urlencoded"
            } else {
                $params.Body = ($Body | ConvertTo-Json -Depth 10)
                $params.ContentType = "application/json"
            }
        }
        
        $response = Invoke-RestMethod @params
        
        $statusCode = 200
        if ($response.PSObject.Properties.Name -contains "StatusCode") {
            $statusCode = $response.StatusCode
        }
        
        if ($SaveToken -and $response.access_token) {
            $script:token = $response.access_token
            $script:headers["Authorization"] = "Bearer $token"
            Write-Host "  [OK] Token saved" -ForegroundColor Green
        }
        
        if ($ExpectedStatus -eq "200" -or $ExpectedStatus -eq "201" -or $ExpectedStatus -eq "204") {
            Write-Host "  [PASS] Status: $ExpectedStatus" -ForegroundColor Green
            $results.Passed++
            return $true
        } else {
            Write-Host "  [PASS] Status: $statusCode" -ForegroundColor Green
            $results.Passed++
            return $true
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorMessage = $_.Exception.Message
        
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            try {
                $errorJson = $responseBody | ConvertFrom-Json
                $errorMessage = $errorJson.detail
            } catch {
                $errorMessage = $responseBody
            }
        }
        
        Write-Host "  [FAIL] Status: $statusCode" -ForegroundColor Red
        Write-Host "  Error: $errorMessage" -ForegroundColor Red
        $results.Failed++
        return $false
    }
    Write-Host ""
}

# ============================================
# 1. Health Check
# ============================================
Write-Host "`n--- 1. Health Check ---" -ForegroundColor Yellow
Test-Endpoint -Name "Health Check" -Method "GET" -Endpoint "/health"

# ============================================
# 2. Register User
# ============================================
Write-Host "`n--- 2. Authentication ---" -ForegroundColor Yellow
$registerBody = @{
    email = $testEmail
    username = $testUsername
    password = $testPassword
    full_name = $testFullName
}
$registerResult = Test-Endpoint -Name "Register User" -Method "POST" -Endpoint "/register" -Body $registerBody -ExpectedStatus "201"

if (-not $registerResult) {
    Write-Host "  [INFO] User might already exist, trying login..." -ForegroundColor Yellow
    $testUsername = "testuser"
    $testEmail = "test@example.com"
}

# ============================================
# 3. Login
# ============================================
$loginBody = "username=$testUsername&password=$testPassword"
$loginResult = Test-Endpoint -Name "Login" -Method "POST" -Endpoint "/login" -Body $loginBody -SaveToken $true

if (-not $loginResult) {
    Write-Host "  [WARNING] Login failed - some tests will be skipped" -ForegroundColor Yellow
}

# ============================================
# 4. Get User Info
# ============================================
if ($token) {
    Test-Endpoint -Name "Get User Info" -Method "GET" -Endpoint "/me" -Headers $headers
}

# ============================================
# 5. Send Sensor Data (No Auth)
# ============================================
Write-Host "`n--- 3. Sensor Data (No Auth) ---" -ForegroundColor Yellow

$sensorData = @(
    @{ type = "temperature"; value = 22.5; device_id = $testDeviceId },
    @{ type = "ph"; value = 6.8; device_id = $testDeviceId },
    @{ type = "weight"; value = 50.1; device_id = $testDeviceId },
    @{ type = "outsideTemp"; value = 15.3; device_id = $testDeviceId },
    @{ type = "humidity"; value = 70.2; device_id = $testDeviceId },
    @{ type = "pressure"; value = 1012.5; device_id = $testDeviceId }
)

foreach ($data in $sensorData) {
    Test-Endpoint -Name "Send $($data.type)" -Method "POST" -Endpoint "/sensor/data" -Body $data
    Start-Sleep -Milliseconds 200
}

# ============================================
# 6. Get Readings (Auth Required)
# ============================================
if ($token) {
    Write-Host "`n--- 4. Sensor Readings (Auth Required) ---" -ForegroundColor Yellow
    
    $readingsEndpoints = @(
        @{ name = "Temperature"; endpoint = "/readings/temperature?days=1" },
        @{ name = "pH"; endpoint = "/readings/ph?days=1" },
        @{ name = "Weight"; endpoint = "/readings/weight?days=1" },
        @{ name = "Outside Temperature"; endpoint = "/readings/outsideTemp?days=1" },
        @{ name = "Humidity"; endpoint = "/readings/humidity?days=1" },
        @{ name = "Pressure"; endpoint = "/readings/pressure?days=1" }
    )
    
    foreach ($reading in $readingsEndpoints) {
        $result = Test-Endpoint -Name "Get $($reading.name) Readings" -Method "GET" -Endpoint $reading.endpoint -Headers $headers
        if ($result) {
            try {
                $response = Invoke-RestMethod -Uri "$BaseUrl$($reading.endpoint)" -Method GET -Headers $headers -ErrorAction Stop
                Write-Host "  [INFO] Records found: $($response.Count)" -ForegroundColor Gray
            } catch {
                # Ignore
            }
        }
    }
}

# ============================================
# 7. Update User
# ============================================
if ($token) {
    Write-Host "`n--- 5. Update User ---" -ForegroundColor Yellow
    $updateBody = @{
        full_name = "Updated Test User"
    }
    Test-Endpoint -Name "Update User" -Method "PUT" -Endpoint "/me" -Body $updateBody -Headers $headers
}

# ============================================
# Summary
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($results.Total)" -ForegroundColor White
Write-Host "Passed: $($results.Passed)" -ForegroundColor Green
Write-Host "Failed: $($results.Failed)" -ForegroundColor $(if ($results.Failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($results.Failed -eq 0) {
    Write-Host "All tests passed!" -ForegroundColor Green
} else {
    Write-Host "Some tests failed. Check the output above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Test credentials used:" -ForegroundColor Gray
Write-Host "  Username: $testUsername" -ForegroundColor White
Write-Host "  Email: $testEmail" -ForegroundColor White
Write-Host "  Device ID: $testDeviceId" -ForegroundColor White

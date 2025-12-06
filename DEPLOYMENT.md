<<<<<<< Updated upstream
# Deployment Guide

## Local Network Setup (Quick - for team development)

### 1. Configure Backend for Network Access

Edit `IoTProject.API/Properties/launchSettings.json` (create if doesn't exist):

```json
{
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "http://0.0.0.0:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "https://0.0.0.0:7000;http://0.0.0.0:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

### 2. Update CORS Configuration

Edit `IoTProject.API/Program.cs` - CORS section should be:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

### 3. Configure Firewall (Windows)

```powershell
# Allow port 5000 (HTTP)
netsh advfirewall firewall add rule name="ASP.NET Core HTTP" dir=in action=allow protocol=TCP localport=5000

# Allow port 7000 (HTTPS)
netsh advfirewall firewall add rule name="ASP.NET Core HTTPS" dir=in action=allow protocol=TCP localport=7000
```

### 4. Find Your Local IP Address

```bash
# Windows
ipconfig

# Linux/Mac
ifconfig
```

Look for IPv4 address (e.g., `192.168.1.100`)

### 5. Start Backend

```bash
cd IoTProject.API
dotnet run --urls "http://0.0.0.0:5000;https://0.0.0.0:7000"
```

### 6. Share Connection Details with Team

Your server is now accessible at:

```
HTTP:  http://YOUR_IP:5000
HTTPS: https://YOUR_IP:7000
Swagger: http://YOUR_IP:5000/swagger

Example: http://192.168.1.100:5000
```

### 7. Team Configuration

Team members should configure their clients:

**Mobile App** (`MobileApp/src/config/api.ts`):
```typescript
export const API_BASE_URL = 'http://192.168.1.100:5000';
export const SIGNALR_HUB_URL = 'http://192.168.1.100:5000/hubs/sensordata';
```

**IoT Devices** - send MQTT to Azure IoT Hub (unchanged)

---

## Opcja 2: Azure App Service (Production)

### Prerequisites

- Azure account
- Azure CLI installed

### 1. Login to Azure

```bash
az login
```

### 2. Create Resources

```bash
# Variables
RESOURCE_GROUP="iot-project-rg"
APP_SERVICE_PLAN="iot-project-plan"
WEB_APP_NAME="iot-project-api-team"  # Must be globally unique
LOCATION="westeurope"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create App Service Plan (Free tier)
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku F1 \
  --is-linux

# Create Web App
az webapp create \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "DOTNET|8.0"
```

### 3. Configure Application Settings

```bash
az webapp config appsettings set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings \
    ASPNETCORE_ENVIRONMENT="Production" \
    ConnectionStrings__DefaultConnection="YOUR_SQL_CONNECTION_STRING" \
    JwtSettings__SecretKey="YOUR_JWT_SECRET" \
    JwtSettings__Issuer="IoTProjectAPI" \
    JwtSettings__Audience="IoTProjectClient" \
    JwtSettings__ExpirationDays="7" \
    AzureIoTHub__ConnectionString="YOUR_IOT_HUB_CONNECTION" \
    AzureIoTHub__EventHubConnectionString="YOUR_EVENT_HUB_CONNECTION" \
    AzureIoTHub__ConsumerGroup='$Default'
```

### 4. Build and Publish

```bash
cd IoTProject.API

# Publish app
dotnet publish -c Release -o ./publish

# Create ZIP
cd publish
tar -czf ../publish.zip .
cd ..

# Deploy to Azure
az webapp deploy \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --src-path publish.zip \
  --type zip
```

### 5. Verify Deployment

```bash
# Test health endpoint
curl https://$WEB_APP_NAME.azurewebsites.net/health
```

### 6. Share URL with Team

```
API URL: https://iot-project-api-team.azurewebsites.net
Swagger: https://iot-project-api-team.azurewebsites.net/swagger
```

Team members update their config:

```typescript
export const API_BASE_URL = 'https://iot-project-api-team.azurewebsites.net';
export const SIGNALR_HUB_URL = 'https://iot-project-api-team.azurewebsites.net/hubs/sensordata';
```

---

## Opcja 3: Docker Container (Alternative)

### 1. Build Docker Image

```bash
docker build -t iot-project-api -f IoTProject.API/Dockerfile .
```

### 2. Run Container

```bash
docker run -d \
  -p 5000:8080 \
  -e ConnectionStrings__DefaultConnection="YOUR_CONNECTION_STRING" \
  -e JwtSettings__SecretKey="YOUR_SECRET" \
  -e AzureIoTHub__ConnectionString="YOUR_IOT_HUB" \
  -e AzureIoTHub__EventHubConnectionString="YOUR_EVENT_HUB" \
  --name iot-api \
  iot-project-api
```

### 3. Access

```
http://YOUR_IP:5000
```

---

## Testing Connection

### From Team Member's Machine

```bash
# Test health
curl http://192.168.1.100:5000/health

# Test register
curl -X POST http://192.168.1.100:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Test","lastName":"User","email":"test@example.com","password":"test123"}'

# Test login
curl -X POST http://192.168.1.100:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

---

## Troubleshooting

### Connection Refused

1. Check firewall rules
2. Verify server is running: `netstat -an | findstr :5000`
3. Ensure all devices on same network
4. Try HTTP (port 5000) instead of HTTPS if certificate issues

### CORS Errors

Ensure `AllowAnyOrigin()` is set in Program.cs CORS configuration.

### SignalR Connection Failed

SignalR requires either HTTP/2 or WebSocket support. Use HTTP endpoint if HTTPS has certificate issues in development.

---

## Security Notes

**For local development:**
- CORS set to allow all origins
- HTTP (not HTTPS) is acceptable
- Share IP only within trusted network

**For production (Azure):**
- Use HTTPS only
- Restrict CORS to specific origins
- Use environment variables for secrets
- Enable Application Insights for monitoring

---

## Quick Reference

| Environment | URL Format | Port |
|------------|------------|------|
| Local (you) | http://localhost:5000 | 5000 |
| Local network | http://192.168.1.X:5000 | 5000 |
| Azure | https://app-name.azurewebsites.net | 443 |
| Docker | http://host-ip:5000 | 5000 |

---

## Team Checklist

- [ ] Backend server running and accessible
- [ ] Firewall configured to allow incoming connections
- [ ] IP address shared with team
- [ ] Team members updated their API configuration
- [ ] Test endpoints responding correctly
- [ ] SignalR hub accessible
- [ ] Azure IoT Hub configured (if using IoT devices)
- [ ] Database accessible from server

=======
# Deployment Guide - Smart Brewery IoT Server

## Wymagania

- Azure CLI zainstalowane i zalogowane (`az login`)
- PowerShell 5.1+ lub PowerShell Core 7+
- Subskrypcja Azure z uprawnieniami do tworzenia zasobów

## Szybki Start

### Opcja 1: Wszystko w jednym (zalecane)

```powershell
.\deploy\quick_deploy.ps1
```

Skrypt automatycznie:
1. Utworzy wszystkie zasoby Azure (jeśli nie istnieją)
2. Zbuduje obraz Docker
3. Wdroży aplikację
4. Skonfiguruje zmienne środowiskowe

### Opcja 2: Krok po kroku

#### Krok 1: Setup Azure Resources

```powershell
.\deploy\setup_azure.ps1
```

**Co zostanie utworzone:**
- Resource Group: `smart-brewery-rg`
- Azure SQL Server: `smart-brewery-sql`
- Azure SQL Database: `smartbrewerydb` (S0 tier)
- Azure Container Registry: `smartbreweryacr`
- Container App Environment: `smart-brewery-env`

**WAŻNE:** Zapisz wygenerowane hasło SQL!

#### Krok 2: Build & Deploy

```powershell
.\deploy\build_and_deploy.ps1 -SqlAdminPassword "YourPassword123!"
```

**Lub interaktywnie (skrypt poprosi o hasło):**

```powershell
.\deploy\build_and_deploy.ps1
```

## Testowanie

Po wdrożeniu, uruchom testy:

```powershell
# Pobierz URL aplikacji
$appUrl = az containerapp show `
    --name smart-brewery `
    --resource-group smart-brewery-rg `
    --query properties.configuration.ingress.fqdn -o tsv

# Uruchom testy
.\test_api.ps1 -BaseUrl "https://$appUrl"
```

## Przykłady użycia API

### 1. Health Check

```bash
curl https://your-app.azurecontainerapps.io/health
```

### 2. Wysyłanie danych z Raspberry Pi

```bash
# Temperature
curl -X POST https://your-app.azurecontainerapps.io/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "temperature", "value": 22.5}'

# pH
curl -X POST https://your-app.azurecontainerapps.io/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "ph", "value": 4.2}'

# Weight
curl -X POST https://your-app.azurecontainerapps.io/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "weight", "value": 25.5}'

# Outside Temperature
curl -X POST https://your-app.azurecontainerapps.io/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "outsideTemp", "value": 18.3}'

# Humidity
curl -X POST https://your-app.azurecontainerapps.io/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "humidity", "value": 65.0}'

# Pressure
curl -X POST https://your-app.azurecontainerapps.io/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "pressure", "value": 1013.25}'
```

### 3. Rejestracja użytkownika

```bash
curl -X POST https://your-app.azurecontainerapps.io/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "myuser",
    "password": "securepassword123",
    "full_name": "John Doe"
  }'
```

### 4. Logowanie

```bash
curl -X POST https://your-app.azurecontainerapps.io/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=myuser&password=securepassword123"
```

**Odpowiedź:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

### 5. Odczyt danych (wymaga tokenu)

```bash
TOKEN="your-access-token-here"

# Temperature (ostatnie 7 dni)
curl -X GET "https://your-app.azurecontainerapps.io/readings/temperature?days=7" \
  -H "Authorization: Bearer $TOKEN"

# pH (ostatnie 30 dni)
curl -X GET "https://your-app.azurecontainerapps.io/readings/ph?days=30" \
  -H "Authorization: Bearer $TOKEN"

# Wszystkie typy sensorów
curl -X GET "https://your-app.azurecontainerapps.io/readings/weight?days=7" \
  -H "Authorization: Bearer $TOKEN"

curl -X GET "https://your-app.azurecontainerapps.io/readings/outsideTemp?days=7" \
  -H "Authorization: Bearer $TOKEN"

curl -X GET "https://your-app.azurecontainerapps.io/readings/humidity?days=7" \
  -H "Authorization: Bearer $TOKEN"

curl -X GET "https://your-app.azurecontainerapps.io/readings/pressure?days=7" \
  -H "Authorization: Bearer $TOKEN"
```

### 6. Informacje o użytkowniku

```bash
curl -X GET https://your-app.azurecontainerapps.io/me \
  -H "Authorization: Bearer $TOKEN"
```

### 7. Aktualizacja użytkownika

```bash
curl -X PUT https://your-app.azurecontainerapps.io/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "John Updated",
    "email": "newemail@example.com"
  }'
```

## Aktualizacja aplikacji

Po zmianach w kodzie, zaktualizuj aplikację:

```powershell
.\deploy\build_and_deploy.ps1 `
    -ImageTag "v2" `
    -SqlAdminPassword "YourPassword123!"
```

## Monitoring i logi

### Sprawdzenie logów

```powershell
az containerapp logs show `
    --name smart-brewery `
    --resource-group smart-brewery-rg `
    --tail 50
```

### Sprawdzenie statusu

```powershell
az containerapp show `
    --name smart-brewery `
    --resource-group smart-brewery-rg `
    --query "properties.runningStatus"
```

### Sprawdzenie zmiennych środowiskowych

```powershell
az containerapp show `
    --name smart-brewery `
    --resource-group smart-brewery-rg `
    --query "properties.template.containers[0].env"
```

## Koszty

**Szacunkowe koszty (West Europe):**
- Azure SQL Database S0: ~$15/miesiąc
- Azure Container Apps (Consumption): ~$0.000012/vCPU-sekunda
- Azure Container Registry Basic: ~$5/miesiąc
- Storage: minimalne

**Łącznie:** ~$20-30/miesiąc przy małym obciążeniu

## Troubleshooting

### Problem: Błąd połączenia z bazą danych

**Rozwiązanie:**
1. Sprawdź, czy firewall SQL Server pozwala na połączenia z Azure
2. Sprawdź connection string w zmiennych środowiskowych
3. Sprawdź logi aplikacji

### Problem: Aplikacja nie startuje

**Rozwiązanie:**
1. Sprawdź logi: `az containerapp logs show ...`
2. Sprawdź, czy obraz został zbudowany poprawnie
3. Sprawdź zmienne środowiskowe

### Problem: 401 Unauthorized

**Rozwiązanie:**
1. Sprawdź, czy token nie wygasł
2. Zaloguj się ponownie
3. Sprawdź format nagłówka: `Authorization: Bearer <token>`

## Dokumentacja API

Po wdrożeniu, dokumentacja Swagger jest dostępna pod:
- **Swagger UI:** `https://your-app.azurecontainerapps.io/docs`
- **ReDoc:** `https://your-app.azurecontainerapps.io/redoc`
>>>>>>> Stashed changes


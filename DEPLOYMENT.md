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



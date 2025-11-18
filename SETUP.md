# Azure Setup Guide

Step-by-step guide to set up Azure resources for the IoT Project.

## Prerequisites

- Azure account (free tier available)
- Azure CLI installed: `az --version`
- Logged in: `az login`

## 1. Create Resource Group

```bash
az group create \
  --name iot-project-rg \
  --location eastus
```

## 2. Create Azure SQL Database

### Create SQL Server

```bash
az sql server create \
  --name iot-project-sql-server \
  --resource-group iot-project-rg \
  --location eastus \
  --admin-user sqladmin \
  --admin-password YourSecurePassword123!
```

### Create Firewall Rule (Allow Azure Services)

```bash
az sql server firewall-rule create \
  --resource-group iot-project-rg \
  --server iot-project-sql-server \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Create Database

```bash
az sql db create \
  --resource-group iot-project-rg \
  --server iot-project-sql-server \
  --name iot_project_db \
  --service-objective Basic \
  --backup-storage-redundancy Local
```

### Get Connection String

```bash
az sql db show-connection-string \
  --server iot-project-sql-server \
  --name iot_project_db \
  --client ado.net
```

**Connection String Format:**
```
Server=tcp:iot-project-sql-server.database.windows.net,1433;Initial Catalog=iot_project_db;Persist Security Info=False;User ID=sqladmin;Password=YourSecurePassword123!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
```

## 3. Create App Service Plan

```bash
az appservice plan create \
  --name iot-api-plan \
  --resource-group iot-project-rg \
  --sku B1 \
  --is-linux
```

## 4. Create Web App

```bash
az webapp create \
  --name iot-api-20241117 \
  --resource-group iot-project-rg \
  --plan iot-api-plan \
  --runtime "DOTNETCORE:8.0"
```

## 5. Configure App Settings

### Connection String

```bash
az webapp config connection-string set \
  --name iot-api-20241117 \
  --resource-group iot-project-rg \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="Server=tcp:iot-project-sql-server.database.windows.net,1433;Initial Catalog=iot_project_db;Persist Security Info=False;User ID=sqladmin;Password=YourSecurePassword123!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
```

### JWT Secret Key

Generate a secure random key (32+ characters):

```bash
# PowerShell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})

# Linux/Mac
openssl rand -base64 32
```

Set in Azure:

```bash
az webapp config appsettings set \
  --name iot-api-20241117 \
  --resource-group iot-project-rg \
  --settings JwtSettings__SecretKey="YourGeneratedSecretKeyHere"
```

### Additional Settings

```bash
az webapp config appsettings set \
  --name iot-api-20241117 \
  --resource-group iot-project-rg \
  --settings \
    JwtSettings__Issuer="IoTProjectAPI" \
    JwtSettings__Audience="IoTProjectClient" \
    JwtSettings__ExpirationDays="7"
```

## 6. Enable WebSocket Support

```bash
az webapp config set \
  --name iot-api-20241117 \
  --resource-group iot-project-rg \
  --web-sockets-enabled true
```

## 7. Deploy Application

```bash
cd IoTProject.API
az webapp up \
  --name iot-api-20241117 \
  --resource-group iot-project-rg \
  --runtime "DOTNETCORE:8.0"
```

## 8. Verify Deployment

```bash
curl https://iot-api-20241117.azurewebsites.net/health
```

## Mobile App Configuration

Update `MobileApp/src/config/api.ts`:

```typescript
export const API_BASE_URL = 'https://iot-api-20241117.azurewebsites.net';
```

## Raspberry Pi Configuration

### WebSocket Endpoint

**Development:**
```
ws://localhost:5000/ws/sensor-data
```

**Production:**
```
wss://iot-api-20241117.azurewebsites.net/ws/sensor-data
```

### Example Connection (Python)

```python
import asyncio
import websockets
import json
from datetime import datetime

async def send_sensor_data():
    uri = "wss://iot-api-20241117.azurewebsites.net/ws/sensor-data"
    async with websockets.connect(uri) as websocket:
        data = {
            "type": "ph",
            "deviceId": "raspberry-pi-01",
            "value": 7.2,
            "metadata": json.dumps({"location": "tank-1"}),
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }
        await websocket.send(json.dumps(data))
        response = await websocket.recv()
        print(f"Response: {response}")

asyncio.run(send_sensor_data())
```

## Troubleshooting

### Database Connection Issues

1. Check firewall rules allow your IP or Azure services
2. Verify connection string format
3. Test connection: `az sql db show-connection-string --server <server> --name <db> --client ado.net`

### WebSocket Issues

1. Ensure WebSocket is enabled: `az webapp config show --name <app> --resource-group <rg> --query webSocketsEnabled`
2. Use `wss://` (secure) in production
3. Check App Service logs: `az webapp log tail --name <app> --resource-group <rg>`

### Deployment Issues

1. Check build logs in Azure Portal
2. Verify runtime: `az webapp show --name <app> --resource-group <rg> --query linuxFxVersion`
3. Review application logs

## Cost Estimation

- **SQL Database Basic**: ~$5/month
- **App Service B1**: ~$13/month (or use F1 free tier)
- **Total**: ~$18/month (or free with student account)

## Cleanup

To delete all resources:

```bash
az group delete --name iot-project-rg --yes
```

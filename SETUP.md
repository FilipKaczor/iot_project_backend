# Setup Guide

## Prerequisites

- .NET 8.0 SDK
- Azure account with active subscription
- Azure CLI installed

## Azure Resources Setup

### 1. Create Resource Group

```bash
az login
az group create --name iot-project-rg --location westeurope
```

### 2. Create Azure SQL Database

```bash
# Create SQL Server
az sql server create \
  --name iot-project-sql-server \
  --resource-group iot-project-rg \
  --location westeurope \
  --admin-user sqladmin \
  --admin-password "YourPassword123!"

# Create Database
az sql db create \
  --resource-group iot-project-rg \
  --server iot-project-sql-server \
  --name iot_project_db \
  --service-objective Basic

# Configure firewall
az sql server firewall-rule create \
  --resource-group iot-project-rg \
  --server iot-project-sql-server \
  --name AllowMyIP \
  --start-ip-address YOUR_IP \
  --end-ip-address YOUR_IP

az sql server firewall-rule create \
  --resource-group iot-project-rg \
  --server iot-project-sql-server \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### 3. Create Azure IoT Hub

```bash
az extension add --name azure-iot

az iot hub create \
  --name iot-project-hub \
  --resource-group iot-project-rg \
  --location westeurope \
  --sku F1 \
  --partition-count 2

# Create IoT device
az iot hub device-identity create \
  --device-id esp32-sensor-01 \
  --hub-name iot-project-hub

# Get connection strings
az iot hub connection-string show --hub-name iot-project-hub --policy-name service
az iot hub connection-string show --hub-name iot-project-hub --default-eventhub
az iot hub device-identity connection-string show --device-id esp32-sensor-01 --hub-name iot-project-hub
```

## Backend Configuration

### 1. Configure appsettings.json

Edit `IoTProject.API/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=tcp:iot-project-sql-server.database.windows.net,1433;Initial Catalog=iot_project_db;User ID=sqladmin;Password=YourPassword123!;Encrypt=True;TrustServerCertificate=False;"
  },
  "JwtSettings": {
    "SecretKey": "your-secret-key-minimum-32-characters-long",
    "Issuer": "IoTProjectAPI",
    "Audience": "IoTProjectClient",
    "ExpirationDays": 7
  },
  "AzureIoTHub": {
    "ConnectionString": "HostName=iot-project-hub.azure-devices.net;SharedAccessKeyName=service;SharedAccessKey=...",
    "EventHubConnectionString": "Endpoint=sb://....servicebus.windows.net/;SharedAccessKeyName=iothubowner;SharedAccessKey=...;EntityPath=iot-project-hub",
    "ConsumerGroup": "$Default"
  }
}
```

### 2. Run Database Migrations

```bash
cd IoTProject.API
dotnet tool install --global dotnet-ef
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### 3. Start Backend Server

```bash
dotnet run
```

Server will start on:
- HTTPS: https://localhost:7000
- HTTP: http://localhost:5000
- Swagger: https://localhost:7000/swagger

## Mobile App Configuration

### 1. Install Dependencies

```bash
cd MobileApp
npm install
```

### 2. Configure API Endpoint

Edit `MobileApp/src/config/api.ts`:

```typescript
// For Android emulator
export const API_BASE_URL = 'https://10.0.2.2:7000';
export const SIGNALR_HUB_URL = 'https://10.0.2.2:7000/hubs/sensordata';

// For physical device (use your computer's IP)
// export const API_BASE_URL = 'https://192.168.1.100:7000';
// export const SIGNALR_HUB_URL = 'https://192.168.1.100:7000/hubs/sensordata';

// For Azure deployment
// export const API_BASE_URL = 'https://iot-project-api.azurewebsites.net';
// export const SIGNALR_HUB_URL = 'https://iot-project-api.azurewebsites.net/hubs/sensordata';
```

### 3. Start Mobile App

```bash
npm start
```

## IoT Device Configuration

### MQTT Endpoint

Devices send data to Azure IoT Hub using MQTT protocol:

**Protocol**: MQTT over TLS  
**Host**: `iot-project-hub.azure-devices.net`  
**Port**: 8883  
**Topic**: `devices/esp32-sensor-01/messages/events/`

### Device Connection String

Use the device connection string obtained from:

```bash
az iot hub device-identity connection-string show \
  --device-id esp32-sensor-01 \
  --hub-name iot-project-hub
```

Format:
```
HostName=iot-project-hub.azure-devices.net;DeviceId=esp32-sensor-01;SharedAccessKey=...
```

### Message Format

Send JSON messages with sensor data:

```json
{
  "ph": 7.2,
  "temperature": 22.5,
  "weight": 45.3,
  "outside": 16.8
}
```

### Test Message

Send test message from CLI:

```bash
az iot device send-d2c-message \
  --device-id esp32-sensor-01 \
  --hub-name iot-project-hub \
  --data '{"ph":7.2,"temperature":22.5,"weight":45.3,"outside":16.8}'
```

## API Endpoints

### Authentication

**POST** `/api/auth/register`
```json
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**POST** `/api/auth/login`
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

### Sensor Data (requires JWT token)

**GET** `/api/sensordata/ph?limit=10`  
**GET** `/api/sensordata/temp?limit=10`  
**GET** `/api/sensordata/weight?limit=10`  
**GET** `/api/sensordata/outside?limit=10`  
**GET** `/api/sensordata/all?limit=10`  
**GET** `/api/sensordata/stats`

### Authorization Header

```
Authorization: Bearer <JWT_TOKEN>
```

## Data Flow

```
IoT Device (ESP32)
    |
    | MQTT (port 8883)
    v
Azure IoT Hub
    |
    | Event Hub endpoint
    v
Backend API (.NET)
    |
    |-- Azure SQL Database (store data)
    |
    |-- SignalR Hub (broadcast real-time)
    |
    v
Mobile App (React Native)
```

## Troubleshooting

### Cannot connect to SQL Server

Check firewall rules and verify connection string.

### IoT Hub connection failed

Verify connection strings in appsettings.json.

### Mobile app cannot connect

For Android emulator, use `10.0.2.2` instead of `localhost`.  
For physical device, use your computer's IP address on the same network.

### SignalR not working

Ensure JWT token is valid and passed correctly in connection URL as query parameter or header.


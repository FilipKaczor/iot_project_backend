# IoT Project Backend - ASP.NET Core + Azure

IoT system integrating Azure IoT Hub, Azure SQL Database, and React Native mobile application. Backend implemented in C# (ASP.NET Core 8.0).

## Technology Stack

### Backend
- **ASP.NET Core 8.0** Web API
- **Entity Framework Core** + Azure SQL
- **Azure IoT Hub SDK** dla C#
- **SignalR** - real-time communication
- **JWT Authentication**
- **Swagger/OpenAPI** - dokumentacja API

### Cloud
- **Azure IoT Hub** (Free F1) - MQTT broker
- **Azure SQL Database** (Basic) - storage
- **Azure App Service** (opcjonalnie) - hosting

### Mobile
- **React Native** + Expo
- **SignalR Client** - real-time updates

## Requirements

- .NET 8.0 SDK - [Download](https://dotnet.microsoft.com/download/dotnet/8.0)
- Visual Studio 2022 or VS Code with C# Dev Kit
- Azure Subscription - [Free tier](https://azure.microsoft.com/free/students/)
- Node.js 18+ (for mobile application)

## Installation and Setup

### 1. Clone repository

```bash
git clone https://github.com/your-repo/iot_project_backend.git
cd iot_project_backend
```

### 2. Azure Configuration

Follow instructions in **[SETUP.md](SETUP.md)**:
- Create Azure SQL Database
- Create Azure IoT Hub
- Obtain connection strings

### 3. Configure appsettings.json

Edit `IoTProject.API/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=twoj-server.database.windows.net;Database=iot_project_db;User Id=sqladmin;Password=TwojeHaslo!;Encrypt=True;"
  },
  "JwtSettings": {
    "SecretKey": "TwojSuperTajnyKluczMinimum32ZnakiDlaProdukcji!",
    "Issuer": "IoTProjectAPI",
    "Audience": "IoTProjectClient",
    "ExpirationDays": 7
  },
  "AzureIoTHub": {
    "ConnectionString": "HostName=twoj-iot-hub.azure-devices.net;SharedAccessKeyName=service;SharedAccessKey=...",
    "EventHubConnectionString": "Endpoint=sb://...servicebus.windows.net/;...;EntityPath=twoj-iot-hub"
  }
}
```

### 4. Run Database Migrations

```bash
cd IoTProject.API
dotnet tool install --global dotnet-ef
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### 5. Start API Server

```bash
dotnet run
# Or with auto-reload: dotnet watch run
```

API available at:
- HTTPS: https://localhost:7000
- HTTP: http://localhost:5000
- Swagger UI: https://localhost:7000/swagger

## API Endpoints

### Authorization

All endpoints (except `/api/auth/*`) require JWT token in header:

```
Authorization: Bearer YOUR_JWT_TOKEN
```

### Auth Endpoints

#### POST `/api/auth/register`
Register new user.

**Request:**
```json
{
  "firstName": "Jan",
  "lastName": "Kowalski",
  "email": "jan@example.com",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGc...",
  "user": {
    "id": 1,
    "firstName": "Jan",
    "lastName": "Kowalski",
    "email": "jan@example.com"
  }
}
```

#### POST `/api/auth/login`
User login.

**Request:**
```json
{
  "email": "jan@example.com",
  "password": "SecurePass123"
}
```

### Sensor Data Endpoints

#### GET `/api/sensordata/ph?limit=10`
Get pH sensor data (default: last 10 records).

#### GET `/api/sensordata/temp?limit=10`
Get temperature sensor data.

#### GET `/api/sensordata/weight?limit=10`
Get weight sensor data.

#### GET `/api/sensordata/outside?limit=10`
Get outside sensor data.

#### GET `/api/sensordata/all?limit=10`
Get all sensor data at once.

**Response:**
```json
{
  "success": true,
  "data": {
    "ph": [
      {
        "id": 1,
        "deviceId": "esp32-sensor-01",
        "value": 7.2,
        "metadata": "{\"ph\":7.2,\"temperature\":22.5}",
        "timestamp": "2024-01-15T10:30:00Z"
      }
    ],
    "temp": [...],
    "weight": [...],
    "outside": [...]
  }
}
```

#### GET `/api/sensordata/stats`
Get measurement statistics.

**Response:**
```json
{
  "success": true,
  "stats": {
    "phCount": 1234,
    "tempCount": 1234,
    "weightCount": 1234,
    "outsideCount": 1234,
    "lastPhTimestamp": "2024-01-15T10:30:00Z",
    ...
  }
}
```

## 🔌 SignalR Real-time

### Hub URL
```
wss://localhost:7000/hubs/sensordata
```

### Połączenie (JavaScript/TypeScript)

```typescript
import * as signalR from '@microsoft/signalr';

const connection = new signalR.HubConnectionBuilder()
  .withUrl('https://localhost:7000/hubs/sensordata', {
    accessTokenFactory: () => yourJwtToken
  })
  .withAutomaticReconnect()
  .build();

// Odbieranie danych z czujników
connection.on('ReceiveSensorUpdate', (data) => {
  console.log('Sensor update:', data);
  // { deviceId, data, timestamp }
});

await connection.start();

// Subscribe do updates
await connection.invoke('SubscribeToUpdates');
```

## Database Structure

### Table `Users`
```sql
Id (int, PK)
FirstName (nvarchar(100))
LastName (nvarchar(100))
Email (nvarchar(255), unique)
PasswordHash (nvarchar(255))
CreatedAt (datetime2)
UpdatedAt (datetime2)
```

### Sensor Tables
`SensorPh`, `SensorTemp`, `SensorWeight`, `SensorOutside`

```sql
Id (int, PK)
DeviceId (nvarchar(100), indexed)
Value (float)
Metadata (nvarchar(max)) -- JSON
Timestamp (datetime2, indexed DESC)
```

## IoT Device Configuration (ESP32/Arduino)

See `Examples/ESP32_IoTHub_Example.ino` for sample ESP32 code.

### Device Connection String

Obtain from: **Azure Portal → IoT Hub → Devices → [your device] → Primary connection string**

```
HostName=twoj-iot-hub.azure-devices.net;DeviceId=esp32-sensor-01;SharedAccessKey=...
```

## Mobile Application

React Native application located in `MobileApp/` directory.

### Installation

```bash
cd MobileApp
npm install

# iOS
npx pod-install
npx react-native run-ios

# Android
npx react-native run-android

# Or Expo
npx expo start
```

### Configuration

Edit `MobileApp/src/config/api.ts`:

```typescript
export const API_BASE_URL = 'https://localhost:7000'; // or Azure URL
```

## Docker

### Build

```bash
docker build -t iot-project-api -f IoTProject.API/Dockerfile .
```

### Run

```bash
docker run -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="..." \
  -e AzureIoTHub__ConnectionString="..." \
  iot-project-api
```

### Docker Compose

```bash
docker-compose up -d
```

## Azure Deployment

### Azure App Service

```bash
# Zaloguj się do Azure
az login

# Utwórz App Service
az webapp up --name iot-project-api --sku F1

# Deploy
dotnet publish -c Release
az webapp deploy --src-path ./IoTProject.API/bin/Release/net8.0/publish.zip
```

### Or via Visual Studio
1. Right-click on project → **Publish**
2. Select **Azure**
3. **Azure App Service (Windows/Linux)**
4. Configure and publish

## Testing

### Unit tests

```bash
dotnet test
```

### Swagger UI

Open: https://localhost:7000/swagger

### cURL examples

```bash
# Register
curl -X POST https://localhost:7000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Test","lastName":"User","email":"test@test.com","password":"test123"}'

# Login
TOKEN=$(curl -X POST https://localhost:7000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}' \
  | jq -r '.token')

# Get sensor data
curl -X GET "https://localhost:7000/api/sensordata/all?limit=10" \
  -H "Authorization: Bearer $TOKEN"
```

## Azure Costs

### Free tier configuration for student projects:
- Azure IoT Hub F1: Free (8,000 messages/day)
- Azure SQL Basic: ~5 PLN/month (~1.25 EUR)
- Azure App Service F1: Free

**Total: ~5 PLN/month (~1.25 EUR)**

## Documentation

- **[SETUP.md](SETUP.md)** - Complete setup guide with Azure configuration
- **[Examples/ESP32_IoTHub_Example.ino](Examples/ESP32_IoTHub_Example.ino)** - ESP32 sample code

## Security

- JWT Authentication
- BCrypt password hashing
- HTTPS enforcement
- SQL injection protection (EF Core parametrized queries)
- CORS configuration
- Azure SQL firewall
- Secrets in appsettings (excluded from git)

## Useful Commands

```bash
# Create new migration
dotnet ef migrations add MigrationName

# Update database
dotnet ef database update

# Rollback to previous migration
dotnet ef database update PreviousMigrationName

# Remove last migration
dotnet ef migrations remove

# Generate SQL script
dotnet ef migrations script

# Check EF tools version
dotnet ef --version
```

## License

ISC

---

Version: 1.0.0


# IoT Project Backend - ASP.NET Core + Azure

<<<<<<< Updated upstream
Production-ready IoT system with MQTT data ingestion from Raspberry Pi and HTTP REST API for mobile application.
=======
Prosty serwer REST API do odbierania danych z czujników Raspberry Pi i udostępniania historycznych danych.
>>>>>>> Stashed changes

## Struktura

<<<<<<< Updated upstream
```
Raspberry Pi → MQTT → Backend → SQL Database
                              ↓
Mobile App ← HTTP REST ← Backend ← SQL Database
```

### Data Flow
- **Raspberry Pi**: Publishes sensor data via MQTT (port 1883)
- **Backend**: MQTT broker receives messages and stores in Azure SQL Database
- **Mobile App**: Retrieves data via HTTP REST API for charts and visualization

## Technology Stack

### Backend
- **ASP.NET Core 8.0** Web API
- **Entity Framework Core** + Azure SQL Database
- **MQTT Broker** (MQTTnet) - for Raspberry Pi sensor data ingestion
- **JWT Authentication** - for mobile app security
- **Swagger/OpenAPI** - API documentation

### Cloud
- **Azure SQL Database** (Basic tier) - data storage
- **Azure App Service** - hosting

### Mobile
- **React Native** + Expo
- **HTTP REST API** - data retrieval

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
- Obtain connection string

### 3. Configure appsettings.json

Edit `IoTProject.API/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=your-server.database.windows.net;Database=iot_project_db;User Id=sqladmin;Password=YourPassword123!;Encrypt=True;"
  },
  "JwtSettings": {
    "SecretKey": "YourSuperSecretKeyMinimum32CharactersLongForProduction!",
    "Issuer": "IoTProjectAPI",
    "Audience": "IoTProjectClient",
    "ExpirationDays": 7
  }
}
```

### 4. Run database migrations

```bash
cd IoTProject.API
dotnet ef database update
```

### 5. Run the application

```bash
dotnet run
```

API will be available at:
- HTTP: `http://localhost:5000`
- HTTPS: `https://localhost:7000`
- Swagger: `https://localhost:7000/swagger`

## API Endpoints

### Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "password": "SecurePassword123!"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}
```

Response includes JWT token for authenticated requests.

### Sensor Data (Requires Authentication)

All endpoints require `Authorization: Bearer <token>` header.

#### Get pH Data
```http
GET /api/sensordata/ph?limit=10
Authorization: Bearer <token>
```

#### Get Temperature Data
```http
GET /api/sensordata/temp?limit=10
Authorization: Bearer <token>
```

#### Get Weight Data
```http
GET /api/sensordata/weight?limit=10
Authorization: Bearer <token>
```

#### Get Outside Data
```http
GET /api/sensordata/outside?limit=10
Authorization: Bearer <token>
```

#### Get All Data
```http
GET /api/sensordata/all?limit=10
Authorization: Bearer <token>
```

#### Get Statistics
```http
GET /api/sensordata/stats
Authorization: Bearer <token>
```

### Health Check

```http
GET /health
```

## MQTT Configuration

### Raspberry Pi Connection

**MQTT Broker**: `your-server` (or IP address)  
**Port**: `1883` (default MQTT port)

**Topics**:
- `sensors/ph` - pH sensor data
- `sensors/temp` - Temperature sensor data
- `sensors/weight` - Weight sensor data
- `sensors/outside` - Outside sensor data

**Message Format** (JSON payload):
```json
{
  "deviceId": "raspberry-pi-01",
  "value": 7.2,
  "metadata": "{\"location\":\"tank-1\"}",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Note**: Sensor type is automatically extracted from the topic name. You can also include `"type": "ph"` in the payload.

### Example Python Client (Raspberry Pi)

```python
import paho.mqtt.client as mqtt
import json
from datetime import datetime

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")

def on_publish(client, userdata, mid):
    print(f"Message published: {mid}")

# Create MQTT client
client = mqtt.Client()
client.on_connect = on_connect
client.on_publish = on_publish

# Connect to broker
client.connect("your-server", 1883, 60)

# Publish sensor data
data = {
    "deviceId": "raspberry-pi-01",
    "value": 7.2,
    "metadata": json.dumps({"location": "tank-1"}),
    "timestamp": datetime.utcnow().isoformat() + "Z"
}

client.publish("sensors/ph", json.dumps(data))
client.loop_start()
```

## Database Structure

### Users
- `Id` (int, PK)
- `FirstName` (string)
- `LastName` (string)
- `Email` (string, unique)
- `PasswordHash` (string)
- `CreatedAt` (datetime)
- `UpdatedAt` (datetime)

### SensorPh
- `Id` (int, PK)
- `DeviceId` (string)
- `Value` (double)
- `Metadata` (string, nullable)
- `Timestamp` (datetime)

### SensorTemp
- `Id` (int, PK)
- `DeviceId` (string)
- `Value` (double)
- `Metadata` (string, nullable)
- `Timestamp` (datetime)

### SensorWeight
- `Id` (int, PK)
- `DeviceId` (string)
- `Value` (double)
- `Metadata` (string, nullable)
- `Timestamp` (datetime)

### SensorOutside
- `Id` (int, PK)
- `DeviceId` (string)
- `Value` (double)
- `Metadata` (string, nullable)
- `Timestamp` (datetime)

## Mobile App Configuration

Update `MobileApp/src/config/api.ts`:

```typescript
export const API_BASE_URL = 'https://your-api.azurewebsites.net';
```

## Docker

### Build

```bash
docker build -t iot-project-api -f IoTProject.API/Dockerfile .
```

### Run

```bash
docker run -p 8080:8080 \
  -e ConnectionStrings__DefaultConnection="your-connection-string" \
  -e JwtSettings__SecretKey="your-secret-key" \
  iot-project-api
```

## Azure Deployment

### Prerequisites

- Azure CLI installed and logged in
- Azure SQL Database created
- Resource group created

### Deploy

```bash
# Windows PowerShell
.\deploy-azure.ps1

# Linux/Mac
./deploy-azure.sh
```

Or manually:

```bash
# Create App Service Plan
az appservice plan create \
  --name iot-api-plan \
  --resource-group your-resource-group \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name iot-api-20241117 \
  --resource-group your-resource-group \
  --plan iot-api-plan \
  --runtime "DOTNETCORE:8.0"

# Configure connection string
az webapp config connection-string set \
  --name iot-api-20241117 \
  --resource-group your-resource-group \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="your-sql-connection-string"

# Configure JWT secret
az webapp config appsettings set \
  --name iot-api-20241117 \
  --resource-group your-resource-group \
  --settings JwtSettings__SecretKey="your-secret-key"

# Deploy
az webapp up \
  --name iot-api-20241117 \
  --resource-group your-resource-group \
  --runtime "DOTNETCORE:8.0"
```

## Testing

### Health Check

```bash
curl https://your-api.azurewebsites.net/health
```

### Register User

```bash
curl -X POST https://your-api.azurewebsites.net/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Test","lastName":"User","email":"test@example.com","password":"test123"}'
```

### Login

```bash
curl -X POST https://your-api.azurewebsites.net/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### Get Sensor Data (with token)

```bash
curl https://your-api.azurewebsites.net/api/sensordata/ph \
  -H "Authorization: Bearer <your-token>"
```

## Security

- JWT tokens with expiration
- Password hashing with BCrypt
- HTTPS enforced in production
- CORS configured for mobile app
- SQL injection protection via Entity Framework

## Costs (Azure Free Tier)

- **Azure SQL Database Basic**: ~$5/month (or use free tier if available)
- **Azure App Service**: Free tier available (F1)
- **Total**: ~$5/month or free with student account

## Useful Commands

```bash
# Create migration
dotnet ef migrations add MigrationName --project IoTProject.API

# Update database
dotnet ef database update --project IoTProject.API

# Run application
dotnet run --project IoTProject.API

# Build
dotnet build

# Publish
dotnet publish -c Release
```

## License

MIT
=======
- **Baza danych**: Azure SQL Database (trwała, nie resetująca się)
- **Endpoint wysyłania**: `POST /sensor/data` - dla Raspberry Pi (bez autoryzacji)
- **Endpointy odczytu**: `GET /readings/*` - wymagają autoryzacji, parametr `days` (1-365)
- **Autoryzacja**: register, login, update user, get user info

## Endpointy

### Sensor Data (bez autoryzacji)

**POST /sensor/data**

Wysyłanie danych z Raspberry Pi:

```bash
curl -X POST https://your-api.com/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "temperature", "value": 22.5, "device_id": "raspberry-pi-brewery"}'
```

**Typy sensorów:**
- `temperature` - temperatura wewnętrzna
- `ph` - wartość pH
- `weight` - waga w kg
- `outsideTemp` - temperatura zewnętrzna
- `humidity` - wilgotność w %
- `pressure` - ciśnienie w hPa

### Readings (wymaga autoryzacji)

**GET /readings/temperature?days=7**
**GET /readings/ph?days=7**
**GET /readings/weight?days=7**
**GET /readings/outsideTemp?days=7**
**GET /readings/humidity?days=7**
**GET /readings/pressure?days=7**

Parametr `days`: 1-365 (domyślnie 7)

### Authentication

**POST /register** - Rejestracja użytkownika
**POST /login** - Logowanie (zwraca token)
**GET /me** - Informacje o użytkowniku (wymaga token)
**PUT /me** - Aktualizacja użytkownika (wymaga token)

## Konfiguracja

Skopiuj `env.example.txt` do `.env` i uzupełnij:

```env
DATABASE_URL=mssql+pyodbc://username:password@server.database.windows.net/database?driver=ODBC+Driver+18+for+SQL+Server&Encrypt=yes&TrustServerCertificate=no
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

## Uruchomienie

### Lokalnie

```bash
pip install -r requirements.txt
uvicorn main:app --reload
```

### Docker

```bash
docker build -t smart-brewery .
docker run -p 8000:8000 --env-file .env smart-brewery
```

## Wdrożenie na Azure

### Szybkie wdrożenie (wszystko w jednym)

```powershell
.\deploy\quick_deploy.ps1
```

### Krok po kroku

1. **Setup Azure Resources:**
```powershell
.\deploy\setup_azure.ps1
```

2. **Build & Deploy:**
```powershell
.\deploy\build_and_deploy.ps1 -SqlAdminPassword "YourPassword"
```

Szczegóły w [deploy/README.md](deploy/README.md)

## Dokumentacja API

Po uruchomieniu serwera:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

>>>>>>> Stashed changes

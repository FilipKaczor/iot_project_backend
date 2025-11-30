# Smart Brewery IoT Server

Azure-hosted IoT server for smart brewery monitoring system. Receives sensor data from Raspberry Pi via MQTT (Azure IoT Hub) and provides REST API for mobile application.

## Architecture

```
┌─────────────────┐     MQTT (8883)      ┌──────────────────┐
│  Raspberry Pi   │ ──────────────────── │  Azure IoT Hub   │
│  (Sensors)      │                      │                  │
└─────────────────┘                      └────────┬─────────┘
                                                  │
                                                  │ Event Trigger
                                                  ▼
┌─────────────────┐     HTTP (443)       ┌──────────────────┐
│  Mobile App     │ ──────────────────── │  Azure App       │
│                 │      REST API        │  Service         │
└─────────────────┘                      │  (FastAPI)       │
                                         └────────┬─────────┘
                                                  │
                                                  ▼
                                         ┌──────────────────┐
                                         │  Azure SQL       │
                                         │  Database        │
                                         └──────────────────┘
```

---

## 🔧 For Hardware Team (Raspberry Pi)

### Connection Details

| Parameter | Value |
|-----------|-------|
| **Protocol** | MQTT 3.1.1 over TLS |
| **Port** | **8883** |
| **Hostname** | `{iot-hub-name}.azure-devices.net` |
| **Username** | `{iot-hub-name}.azure-devices.net/{device-id}/?api-version=2021-04-12` |
| **Topic** | `devices/{device-id}/messages/events/` |

### JSON Payload Formats

All messages must be valid JSON with a `type` field to identify the sensor.

#### 1. Weight Sensor
```json
{
    "type": "weight",
    "device_id": "raspberry-pi-01",
    "weight_kg": 25.5,
    "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 2. Temperature Sensor (Internal)
```json
{
    "type": "temperature",
    "device_id": "raspberry-pi-01",
    "temperature_celsius": 18.5,
    "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 3. pH Sensor
```json
{
    "type": "ph",
    "device_id": "raspberry-pi-01",
    "ph_value": 4.2,
    "timestamp": "2024-01-15T10:30:00Z"
}
```

#### 4. Environment Sensor (External)
```json
{
    "type": "environment",
    "device_id": "raspberry-pi-01",
    "humidity_percent": 65.0,
    "temperature_celsius": 22.0,
    "pressure_hpa": 1013.25,
    "timestamp": "2024-01-15T10:30:00Z"
}
```

### Python Example (Raspberry Pi)

```python
from azure.iot.device import IoTHubDeviceClient, Message
import json

# Connection string from Azure IoT Hub
CONNECTION_STRING = "HostName=xxx.azure-devices.net;DeviceId=xxx;SharedAccessKey=xxx"

client = IoTHubDeviceClient.create_from_connection_string(CONNECTION_STRING)
client.connect()

# Send weight reading
data = {
    "type": "weight",
    "device_id": "raspberry-pi-01",
    "weight_kg": 25.5
}
message = Message(json.dumps(data))
message.content_encoding = "utf-8"
message.content_type = "application/json"
client.send_message(message)
```

---

## 📱 For Mobile App Team

### Base URL
```
https://{app-name}.azurewebsites.net
```

### API Endpoints

#### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/health` | ❌ | Health check |
| POST | `/register` | ❌ | Register new user |
| POST | `/login` | ❌ | Login and get JWT token |
| GET | `/user_info` | ✅ | Get current user info |

#### Sensor Data (All require authentication)

| Method | Endpoint | Parameters | Description |
|--------|----------|------------|-------------|
| GET | `/readings/weight` | `days` (1-365) | Weight sensor data |
| GET | `/readings/temperature` | `days` (1-365) | Internal temperature data |
| GET | `/readings/ph` | `days` (1-365) | pH sensor data |
| GET | `/readings/environment` | `days` (1-365) | External environment data |

### Authentication Flow

1. **Register** a new user:
```http
POST /register
Content-Type: application/json

{
    "email": "user@example.com",
    "username": "brewer1",
    "password": "securepassword",
    "full_name": "John Brewer"
}
```

2. **Login** to get token:
```http
POST /login
Content-Type: application/json

{
    "username": "brewer1",
    "password": "securepassword"
}
```

Response:
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer"
}
```

3. **Use token** in subsequent requests:
```http
GET /readings/weight?days=7
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Example Responses

#### GET /readings/weight?days=7
```json
[
    {
        "id": 1,
        "device_id": "raspberry-pi-01",
        "weight_kg": 25.5,
        "timestamp": "2024-01-15T10:30:00Z"
    },
    {
        "id": 2,
        "device_id": "raspberry-pi-01",
        "weight_kg": 25.3,
        "timestamp": "2024-01-15T11:30:00Z"
    }
]
```

#### GET /readings/environment?days=3
```json
[
    {
        "id": 1,
        "device_id": "raspberry-pi-01",
        "humidity_percent": 65.0,
        "temperature_celsius": 22.0,
        "pressure_hpa": 1013.25,
        "timestamp": "2024-01-15T10:30:00Z"
    }
]
```

#### GET /user_info
```json
{
    "id": 1,
    "email": "user@example.com",
    "username": "brewer1",
    "full_name": "John Brewer",
    "is_active": true,
    "created_at": "2024-01-10T08:00:00Z"
}
```

### Error Responses

```json
{
    "detail": "Incorrect username or password"
}
```

```json
{
    "detail": "Invalid authentication credentials"
}
```

---

## 🚀 Deployment

### Local Development

1. Create virtual environment:
```bash
python -m venv venv
venv\Scripts\activate  # Windows
source venv/bin/activate  # Linux/Mac
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure environment:
```bash
copy env.example.txt .env
# Edit .env with your settings
```

4. Run server:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

5. Access API docs: http://localhost:8000/docs

### Azure Deployment

#### 1. Create Azure Resources

```bash
# Login to Azure
az login

# Create resource group
az group create --name smart-brewery-rg --location westeurope

# Create App Service Plan (B1 tier - cost effective)
az appservice plan create \
    --name smart-brewery-plan \
    --resource-group smart-brewery-rg \
    --sku B1 \
    --is-linux

# Create Web App
az webapp create \
    --name smart-brewery-api \
    --resource-group smart-brewery-rg \
    --plan smart-brewery-plan \
    --runtime "PYTHON:3.11"

# Create Azure SQL Database
az sql server create \
    --name smart-brewery-sql \
    --resource-group smart-brewery-rg \
    --admin-user adminuser \
    --admin-password YourPassword123!

az sql db create \
    --name smart_brewery \
    --server smart-brewery-sql \
    --resource-group smart-brewery-rg \
    --service-objective Basic

# Create IoT Hub (Free tier)
az iot hub create \
    --name smart-brewery-hub \
    --resource-group smart-brewery-rg \
    --sku F1
```

#### 2. Configure App Settings

```bash
az webapp config appsettings set \
    --name smart-brewery-api \
    --resource-group smart-brewery-rg \
    --settings \
    DATABASE_URL="mssql+pyodbc://adminuser:YourPassword123!@smart-brewery-sql.database.windows.net/smart_brewery?driver=ODBC+Driver+18+for+SQL+Server" \
    SECRET_KEY="your-production-secret-key"
```

#### 3. Deploy Code

```bash
# Using ZIP deploy
az webapp deployment source config-zip \
    --name smart-brewery-api \
    --resource-group smart-brewery-rg \
    --src app.zip
```

---

## 📊 Database Schema

### Tables

#### users
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| email | VARCHAR(255) | User email |
| username | VARCHAR(100) | Unique username |
| hashed_password | VARCHAR(255) | Bcrypt hash |
| full_name | VARCHAR(255) | Full name |
| is_active | BOOLEAN | Account status |
| created_at | DATETIME | Registration date |

#### weight_readings
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| device_id | VARCHAR(100) | Sensor device ID |
| weight_kg | FLOAT | Weight in kg |
| timestamp | DATETIME | Reading time |

#### temperature_readings
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| device_id | VARCHAR(100) | Sensor device ID |
| temperature_celsius | FLOAT | Temperature in °C |
| timestamp | DATETIME | Reading time |

#### ph_readings
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| device_id | VARCHAR(100) | Sensor device ID |
| ph_value | FLOAT | pH value (0-14) |
| timestamp | DATETIME | Reading time |

#### environment_readings
| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| device_id | VARCHAR(100) | Sensor device ID |
| humidity_percent | FLOAT | Humidity % |
| temperature_celsius | FLOAT | External temp °C |
| pressure_hpa | FLOAT | Pressure in hPa |
| timestamp | DATETIME | Reading time |

---

## 💰 Cost Estimation (Azure)

| Resource | Tier | Monthly Cost |
|----------|------|--------------|
| App Service | B1 | ~$13 |
| SQL Database | Basic | ~$5 |
| IoT Hub | F1 (Free) | $0 |
| **Total** | | **~$18/month** |

*For production with higher load, consider scaling to S1 App Service and Standard SQL tier.*

---

## 📁 Project Structure

```
smart-brewery/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── config.py            # Configuration settings
│   ├── database.py          # Database connection
│   ├── azure_function.py    # IoT Hub message handler
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py          # User model
│   │   └── readings.py      # Sensor reading models
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── user.py          # User schemas
│   │   └── readings.py      # Reading schemas
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── health.py        # Health endpoint
│   │   ├── auth.py          # Auth endpoints
│   │   └── readings.py      # Data endpoints
│   └── services/
│       ├── __init__.py
│       ├── auth.py          # Authentication service
│       └── mqtt_handler.py  # MQTT message handler
├── azure-deploy/
│   ├── host.json
│   └── function.json
├── requirements.txt
├── env.example.txt
└── README.md
```


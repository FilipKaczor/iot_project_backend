# Mobile App Team Guide - REST API Integration

## Quick Start

### Base URL

**Local Development:**
```
http://localhost:8000
```

**Production (Azure):**
```
https://{app-name}.azurewebsites.net
```

### API Documentation

Interactive docs available at:
- Swagger UI: `{base_url}/docs`
- ReDoc: `{base_url}/redoc`

---

## Authentication

All sensor reading endpoints require Bearer token authentication.

### Step 1: Register User

```http
POST /register
Content-Type: application/json

{
    "email": "user@example.com",
    "username": "brewer1",
    "password": "securepassword123",
    "full_name": "John Brewer"
}
```

**Response (201 Created):**
```json
{
    "id": 1,
    "email": "user@example.com",
    "username": "brewer1",
    "full_name": "John Brewer",
    "is_active": true,
    "created_at": "2024-01-15T10:30:00Z"
}
```

### Step 2: Login

```http
POST /login
Content-Type: application/json

{
    "username": "brewer1",
    "password": "securepassword123"
}
```

**Response (200 OK):**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
}
```

### Step 3: Use Token

Include the token in all subsequent requests:

```http
GET /readings/weight?days=7
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Endpoints Reference

### Public Endpoints (No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API info |
| GET | `/health` | Health check |
| POST | `/register` | Register user |
| POST | `/login` | Get JWT token |

### Protected Endpoints (Auth Required)

| Method | Endpoint | Parameters | Description |
|--------|----------|------------|-------------|
| GET | `/user_info` | - | Current user info |
| GET | `/readings/weight` | `days` (1-365) | Weight readings |
| GET | `/readings/temperature` | `days` (1-365) | Temperature readings |
| GET | `/readings/ph` | `days` (1-365) | pH readings |
| GET | `/readings/environment` | `days` (1-365) | Environment readings |

---

## Response Examples

### GET /health

```json
{
    "status": "healthy",
    "service": "Smart Brewery IoT Server",
    "database": "healthy"
}
```

### GET /user_info

```json
{
    "id": 1,
    "email": "user@example.com",
    "username": "brewer1",
    "full_name": "John Brewer",
    "is_active": true,
    "created_at": "2024-01-15T10:30:00Z"
}
```

### GET /readings/weight?days=7

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

### GET /readings/temperature?days=7

```json
[
    {
        "id": 1,
        "device_id": "raspberry-pi-01",
        "temperature_celsius": 18.5,
        "timestamp": "2024-01-15T10:30:00Z"
    }
]
```

### GET /readings/ph?days=7

```json
[
    {
        "id": 1,
        "device_id": "raspberry-pi-01",
        "ph_value": 4.2,
        "timestamp": "2024-01-15T10:30:00Z"
    }
]
```

### GET /readings/environment?days=7

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

---

## Error Responses

### 400 Bad Request

```json
{
    "detail": "Email already registered"
}
```

### 401 Unauthorized

```json
{
    "detail": "Incorrect username or password"
}
```

### 403 Forbidden (Missing Token)

```json
{
    "detail": "Not authenticated"
}
```

### 422 Validation Error

```json
{
    "detail": [
        {
            "type": "int_parsing",
            "loc": ["query", "days"],
            "msg": "Input should be a valid integer",
            "input": "invalid"
        }
    ]
}
```

---

## Code Examples

### JavaScript/React Native

```javascript
const API_URL = 'http://localhost:8000';

// Login
async function login(username, password) {
    const response = await fetch(`${API_URL}/login`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
    });
    const data = await response.json();
    return data.access_token;
}

// Get readings with auth
async function getWeightReadings(token, days = 7) {
    const response = await fetch(`${API_URL}/readings/weight?days=${days}`, {
        headers: {
            'Authorization': `Bearer ${token}`,
        },
    });
    return response.json();
}

// Usage
const token = await login('brewer1', 'password123');
const weights = await getWeightReadings(token, 30);
console.log(weights);
```

### Flutter/Dart

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BreweryApi {
  final String baseUrl = 'http://localhost:8000';
  String? _token;

  Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body);
    _token = data['access_token'];
  }

  Future<List<dynamic>> getWeightReadings({int days = 7}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/readings/weight?days=$days'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getTemperatureReadings({int days = 7}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/readings/temperature?days=$days'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getPhReadings({int days = 7}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/readings/ph?days=$days'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getEnvironmentReadings({int days = 7}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/readings/environment?days=$days'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }
}
```

### Kotlin (Android)

```kotlin
import retrofit2.http.*

interface BreweryApi {
    @POST("login")
    suspend fun login(@Body credentials: LoginRequest): TokenResponse

    @GET("user_info")
    suspend fun getUserInfo(@Header("Authorization") token: String): UserResponse

    @GET("readings/weight")
    suspend fun getWeightReadings(
        @Header("Authorization") token: String,
        @Query("days") days: Int = 7
    ): List<WeightReading>

    @GET("readings/temperature")
    suspend fun getTemperatureReadings(
        @Header("Authorization") token: String,
        @Query("days") days: Int = 7
    ): List<TemperatureReading>

    @GET("readings/ph")
    suspend fun getPhReadings(
        @Header("Authorization") token: String,
        @Query("days") days: Int = 7
    ): List<PhReading>

    @GET("readings/environment")
    suspend fun getEnvironmentReadings(
        @Header("Authorization") token: String,
        @Query("days") days: Int = 7
    ): List<EnvironmentReading>
}

data class LoginRequest(val username: String, val password: String)
data class TokenResponse(val access_token: String, val token_type: String)
data class WeightReading(val id: Int, val device_id: String, val weight_kg: Double, val timestamp: String)
// ... other data classes
```

---

## Testing with cURL

```bash
# Health check
curl http://localhost:8000/health

# Register
curl -X POST http://localhost:8000/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","username":"testuser","password":"test123"}'

# Login
curl -X POST http://localhost:8000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}'

# Get readings (replace TOKEN with actual token)
curl http://localhost:8000/readings/weight?days=7 \
  -H "Authorization: Bearer TOKEN"
```

---

## Postman Collection

Import `postman_collection.json` from the project root for ready-to-use test requests.


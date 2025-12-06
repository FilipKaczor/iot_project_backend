# Testowanie API w Postman

## Import kolekcji

1. Otwórz Postman
2. Kliknij **Import** (lewy górny róg)
3. Wybierz plik: `Smart_Brewery_API.postman_collection.json`
4. Kolekcja zostanie zaimportowana z wszystkimi endpointami

## Kolejność testowania

### 1. Health Check ✅
- **Endpoint**: `GET /health`
- **Opis**: Sprawdza czy API działa
- **Oczekiwany wynik**: Status 200, `{"status": "healthy", ...}`

### 2. Rejestracja użytkownika 👤
- **Endpoint**: `POST /register`
- **Body**: 
  ```json
  {
    "email": "test@example.com",
    "username": "testuser",
    "password": "TestPassword123!",
    "full_name": "Test User"
  }
  ```
- **Oczekiwany wynik**: Status 201, zwraca dane użytkownika

### 3. Logowanie 🔐
- **Endpoint**: `POST /login`
- **Body** (form-urlencoded):
  - `username`: `testuser`
  - `password`: `TestPassword123!`
- **Ważne**: Token jest automatycznie zapisywany do zmiennej `access_token`
- **Oczekiwany wynik**: Status 200, `{"access_token": "...", "token_type": "bearer"}`

### 4. Sprawdzenie użytkownika 👤
- **Endpoint**: `GET /me`
- **Wymaga**: Token w headerze (automatycznie dodawany)
- **Oczekiwany wynik**: Status 200, zwraca dane zalogowanego użytkownika

### 5. Wysyłanie danych z czujników 📊
**Bez autoryzacji** - można wysyłać w dowolnej kolejności:

- **POST /sensor/data** - Temperature
  ```json
  {
    "type": "temperature",
    "value": 22.5,
    "device_id": "raspberry-pi-brewery"
  }
  ```

- **POST /sensor/data** - pH
  ```json
  {
    "type": "ph",
    "value": 6.8,
    "device_id": "raspberry-pi-brewery"
  }
  ```

- **POST /sensor/data** - Weight
  ```json
  {
    "type": "weight",
    "value": 50.1,
    "device_id": "raspberry-pi-brewery"
  }
  ```

- **POST /sensor/data** - Outside Temperature
  ```json
  {
    "type": "outsideTemp",
    "value": 15.3,
    "device_id": "raspberry-pi-brewery"
  }
  ```

- **POST /sensor/data** - Humidity
  ```json
  {
    "type": "humidity",
    "value": 70.2,
    "device_id": "raspberry-pi-brewery"
  }
  ```

- **POST /sensor/data** - Pressure
  ```json
  {
    "type": "pressure",
    "value": 1012.5,
    "device_id": "raspberry-pi-brewery"
  }
  ```

### 6. Pobieranie odczytów 📈
**Wymaga autoryzacji** - token jest automatycznie dodawany:

- **GET /readings/temperature?days=7**
- **GET /readings/ph?days=7**
- **GET /readings/weight?days=7**
- **GET /readings/outsideTemp?days=7**
- **GET /readings/humidity?days=7**
- **GET /readings/pressure?days=7**

Parametr `days` (1-365) określa ile dni wstecz pobrać dane.

### 7. Aktualizacja użytkownika ✏️
- **Endpoint**: `PUT /me`
- **Body**:
  ```json
  {
    "full_name": "Updated Test User"
  }
  ```
- **Wymaga**: Token

### 8. Usunięcie wszystkich odczytów 🗑️
- **Endpoint**: `DELETE /readings/clear-all-readings`
- **Wymaga**: Token
- **Uwaga**: Usuwa wszystkie dane z bazy!

## Zmienne w kolekcji

Kolekcja używa następujących zmiennych:

- `base_url` - URL API (domyślnie: `https://smart-brewery.wittyforest-43b9cebb.westeurope.azurecontainerapps.io`)
- `access_token` - Token JWT (automatycznie ustawiany po logowaniu)
- `device_id` - ID urządzenia (domyślnie: `raspberry-pi-brewery`)

Możesz zmienić te wartości w zakładce **Variables** w kolekcji.

## Szybki test

Minimalny workflow:
1. Health Check
2. Register User
3. Login (zapisuje token)
4. Send Temperature (lub inny sensor)
5. Get Temperature Readings

## Troubleshooting

- **401 Unauthorized**: Upewnij się, że wykonałeś Login i token został zapisany
- **400 Bad Request**: Sprawdź format JSON w body
- **500 Internal Server Error**: Sprawdź logi w Azure Portal


# Deployment Guide

## Krok 1: Setup Azure Resources

Uruchom skrypt, który utworzy wszystkie potrzebne zasoby Azure:

```powershell
.\deploy\setup_azure.ps1
```

**Lub z własnymi parametrami:**

```powershell
.\deploy\setup_azure.ps1 `
    -ResourceGroupName "smart-brewery-rg" `
    -Location "West Europe" `
    -SqlServerName "smart-brewery-sql" `
    -SqlDatabaseName "smartbrewerydb" `
    -AcrName "smartbreweryacr" `
    -ContainerAppName "smart-brewery" `
    -SqlAdminUser "sqladmin" `
    -SqlAdminPassword "YourSecurePassword123!"
```

**WAŻNE:** Zapisz wygenerowane hasło SQL!

## Krok 2: Build & Deploy

Zbuduj i wdróż aplikację:

```powershell
.\deploy\build_and_deploy.ps1 `
    -SqlAdminPassword "YourSecurePassword123!" `
    -SecretKey "your-jwt-secret-key-here"
```

**Lub bez parametrów (skrypt poprosi o hasło):**

```powershell
.\deploy\build_and_deploy.ps1
```

## Krok 3: Testowanie

### Health Check
```bash
curl https://your-app-url.azurecontainerapps.io/health
```

### Wysyłanie danych z RPi
```bash
curl -X POST https://your-app-url.azurecontainerapps.io/sensor/data \
  -H "Content-Type: application/json" \
  -d '{"type": "temperature", "value": 22.5}'
```

### Rejestracja użytkownika
```bash
curl -X POST https://your-app-url.azurecontainerapps.io/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "testuser",
    "password": "password123",
    "full_name": "Test User"
  }'
```

### Logowanie
```bash
curl -X POST https://your-app-url.azurecontainerapps.io/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser&password=password123"
```

### Odczyt danych (wymaga tokenu)
```bash
TOKEN="your-access-token-here"
curl -X GET "https://your-app-url.azurecontainerapps.io/readings/temperature?days=7" \
  -H "Authorization: Bearer $TOKEN"
```

## Aktualizacja aplikacji

Aby zaktualizować aplikację po zmianach w kodzie:

```powershell
.\deploy\build_and_deploy.ps1 `
    -ImageTag "v2" `
    -SqlAdminPassword "YourSecurePassword123!"
```

## Troubleshooting

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


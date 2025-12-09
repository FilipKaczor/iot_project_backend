# Azure Web App Deployment Guide

## 🚀 Szybki Start

### 1. Utwórz infrastrukturę Azure
```powershell
.\deploy\setup_webapp.ps1
```

To utworzy:
- Resource Group
- Azure SQL Server + Database
- App Service Plan (B1 - Linux)
- Web App (Python 3.11)

### 2. Wdróż aplikację
```powershell
.\deploy\deploy_webapp.ps1
```

## 📋 Szczegóły

### Wymagania
- Azure CLI zainstalowane i zalogowane
- PowerShell 5.1+
- Python 3.11 (lokalnie, tylko do testów)

### Parametry (opcjonalne)

#### setup_webapp.ps1
```powershell
.\deploy\setup_webapp.ps1 `
    -ResourceGroupName "smart-brewery-rg-webapp" `
    -Location "West Europe" `
    -SqlServerName "smart-brewery-sql-webapp" `
    -WebAppName "smart-brewery-webapp" `
    -SqlAdminPassword "TwojeHaslo123"
```

#### deploy_webapp.ps1
```powershell
.\deploy\deploy_webapp.ps1 `
    -ResourceGroupName "smart-brewery-rg-webapp" `
    -WebAppName "smart-brewery-webapp" `
    -SecretKey "TwojSecretKey"
```

## 🔧 Konfiguracja

### HTTP/1.1
Web App domyślnie obsługuje HTTP/1.1. Skrypt wyłącza HTTP/2 dla kompatybilności:
```powershell
az webapp config set --http20-enabled false
```

### Port
Azure Web App automatycznie ustawia zmienną środowiskową `PORT`. 
Aplikacja używa `startup.sh` który czyta tę zmienną.

### Environment Variables
Aplikacja używa następujących zmiennych środowiskowych:
- `DATABASE_URL` - Connection string do Azure SQL
- `SECRET_KEY` - JWT secret key
- `ACCESS_TOKEN_EXPIRE_MINUTES` - Czas ważności tokenu (domyślnie 30)
- `PORT` - Port (ustawiany automatycznie przez Azure)

## 📦 Struktura Deployment

```
deploy.zip zawiera:
├── app/              # Kod aplikacji
├── main.py           # Entry point
├── requirements.txt  # Zależności Python
├── startup.sh        # Startup script
└── .deployment       # Azure deployment config
```

## 🧪 Testowanie

Po deployment, sprawdź:
```bash
# Health check
curl https://smart-brewery-webapp.azurewebsites.net/health

# API Info
curl https://smart-brewery-webapp.azurewebsites.net/

# Documentation
# Otwórz w przeglądarce:
https://smart-brewery-webapp.azurewebsites.net/docs
```

## 🔍 Logi

Zobacz logi aplikacji:
```powershell
az webapp log tail --name smart-brewery-webapp --resource-group smart-brewery-rg-webapp
```

Lub w Azure Portal:
- Web App → Log stream

## 🔄 Re-deployment

Aby wdrożyć ponownie po zmianach:
```powershell
.\deploy\deploy_webapp.ps1
```

## 🐛 Troubleshooting

### Aplikacja nie startuje
1. Sprawdź logi: `az webapp log tail`
2. Sprawdź startup command: `az webapp config show --name <app> --query linuxFxVersion`
3. Upewnij się że `startup.sh` jest w root katalogu

### Błąd połączenia z bazą danych
1. Sprawdź firewall rules w SQL Server
2. Sprawdź connection string w App Settings
3. Sprawdź czy DATABASE_URL jest poprawnie ustawione

### 502 Bad Gateway
- Sprawdź czy aplikacja startuje (logi)
- Sprawdź czy PORT jest używany poprawnie
- Sprawdź startup.sh

### HTTP/1.1 nie działa
- Sprawdź: `az webapp config show --name <app> --query http20Enabled`
- Powinno być: `false`

## 💰 Koszty

- **App Service Plan B1**: ~$13/miesiąc
- **SQL Database S0**: ~$15/miesiąc
- **Total**: ~$28/miesiąc

Możesz użyć darmowych tierów dla testów:
- App Service: F1 (Free)
- SQL Database: Basic (najtańszy)

## 🧹 Cleanup

Aby usunąć wszystkie zasoby:
```powershell
az group delete --name smart-brewery-rg-webapp --yes --no-wait
```

## 📝 Notatki

- Web App używa **gunicorn** z **uvicorn workers** dla lepszej wydajności
- HTTP/1.1 jest domyślnie włączone
- Wszystkie endpointy zwracają JSON
- CORS jest włączony dla wszystkich originów (dla projektu edukacyjnego)


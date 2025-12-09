# CO USTAWIĆ W PORTALU AZURE - KONKRETNA LISTA

## Idź do: https://portal.azure.com → Web App: smart-brewery-webapp

---

## 1. CONFIGURATION → Application settings

Kliknij **"+ New application setting"** i dodaj:

### Setting 1:
- **Name**: `DATABASE_URL`
- **Value**: `mssql+pymssql://sqladmin:TWOJE_HASLO@smart-brewery-sql-webapp.database.windows.net:1433/smartbrewerydb`
  (Zamień TWOJE_HASLO na hasło z SQL)

### Setting 2:
- **Name**: `SECRET_KEY`
- **Value**: `MVis7QDPbOm3aAIR2NHwqKXgJfTcSE9L`

### Setting 3:
- **Name**: `SCM_DO_BUILD_DURING_DEPLOYMENT`
- **Value**: `true`

**KLIKNIJ SAVE U GÓRY!**

---

## 2. CONFIGURATION → General settings

Przewiń w dół do **"Startup Command"** i wpisz:

```
gunicorn main:app --workers 2 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --timeout 600
```

**KLIKNIJ SAVE U GÓRY!**

---

## 3. DEPLOYMENT CENTER

### Opcja A - ZIP (prostsze):

1. Kliknij **"Local Git/FTP"** → **"FTPS credentials"**
2. W **"User scope"**:
   - Username: `brewery-deploy`
   - Password: `Deploy123!`
   - **SAVE**

3. Użyj PowerShell:
```powershell
# W katalogu projektu:
.\prepare_deployment.ps1

# Potem:
az webapp deploy --resource-group smart-brewery-rg-webapp --name smart-brewery-webapp --src-path deploy_package.zip --type zip --async false
```

### Opcja B - GitHub (jeśli masz repo):

1. **Source**: `GitHub`
2. Authorize i wybierz repo
3. Branch: `main`
4. **Save**

---

## 4. RESTART

Kliknij **"Restart"** u góry → **"Yes"**

Poczekaj 2 minuty.

---

## 5. TEST

Otwórz w przeglądarce:
- https://smart-brewery-webapp.azurewebsites.net/
- https://smart-brewery-webapp.azurewebsites.net/health
- https://smart-brewery-webapp.azurewebsites.net/docs

---

## JEŚLI NADAL NIE DZIAŁA:

### Sprawdź logi:

1. **Log stream** (lewe menu)
2. Szukaj błędów czerwonym tekstem

### Najpopularniejsze problemy:

**Problem**: `startup.sh: not found`
**Rozwiązanie**: Usuń "startup.sh" z Startup Command, wpisz bezpośrednio gunicorn command (jak w kroku 2)

**Problem**: `DATABASE_URL` error
**Rozwiązanie**: Sprawdź format connection stringa w Application settings (krok 1)

**Problem**: `Module not found`
**Rozwiązanie**: Upewnij się że `SCM_DO_BUILD_DURING_DEPLOYMENT=true` jest ustawione

---

## CO ZAWIERA deploy_package.zip:

```
deploy_package/
├── app/
│   ├── __init__.py
│   ├── config.py
│   ├── database.py
│   ├── main.py
│   ├── models/
│   ├── routers/
│   ├── schemas/
│   └── services/
├── main.py
├── requirements.txt
└── .deployment
```

---

## SZYBKIE SPRAWDZENIE CZY DZIAŁA:

```powershell
curl.exe https://smart-brewery-webapp.azurewebsites.net/health
```

Powinieneś zobaczyć:
```json
{"status":"healthy","service":"Smart Brewery IoT Server","database":"healthy"}
```


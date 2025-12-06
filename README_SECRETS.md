# 🔐 Zarządzanie Sekretami

## Gdzie zapisać hasła?

**Odpowiedź:** W pliku `secrets.txt` (automatycznie tworzony przez skrypty)

## Automatyczne zapisywanie

Skrypt `setup_azure.ps1` **automatycznie zapisuje** wszystkie hasła do pliku `secrets.txt`:

```
secrets.txt
├── SQL_ADMIN_PASSWORD=4JDqZyTASkb7Ra1e
├── SQL_SERVER_NAME=smart-brewery-sql
├── SQL_DATABASE_NAME=smartbrewerydb
├── SQL_ADMIN_USER=sqladmin
└── ... (inne konfiguracje)
```

## Bezpieczeństwo

✅ **Plik `secrets.txt` jest w `.gitignore`** - NIE zostanie commitowany do repozytorium

✅ **Skrypty automatycznie ładują hasła** z `secrets.txt` - nie musisz ich wpisywać za każdym razem

## Co zrobić teraz?

### 1. Sprawdź plik secrets.txt

Po uruchomieniu `setup_azure.ps1`, sprawdź czy plik został utworzony:

```powershell
cat secrets.txt
```

### 2. Jeśli plik nie istnieje, utwórz go ręcznie:

```powershell
# Skopiuj przykład
Copy-Item secrets.example.txt secrets.txt

# Edytuj i uzupełnij hasła
notepad secrets.txt
```

### 3. Użyj skryptów - automatycznie załadują hasła:

```powershell
# Skrypt automatycznie załaduje hasło z secrets.txt
.\deploy\build_and_deploy.ps1
```

## Ważne!

⚠️ **NIE COMMITUJ `secrets.txt` DO GIT!**

Plik jest już w `.gitignore`, ale upewnij się:

```bash
git check-ignore secrets.txt
# Powinno zwrócić: secrets.txt
```

## Backup hasła

Zapisz hasło w bezpiecznym miejscu (np. password manager):

- **SQL Password:** `4JDqZyTASkb7Ra1e`
- **SQL Server:** `smart-brewery-sql.database.windows.net`
- **SQL Database:** `smartbrewerydb`
- **SQL User:** `sqladmin`

## Odzyskiwanie hasła

Jeśli zgubisz hasło SQL:

1. Zresetuj w Azure Portal:
   - Azure SQL Server → Security → Reset password

2. Zaktualizuj `secrets.txt` z nowym hasłem

3. Zaktualizuj Container App:
   ```powershell
   .\deploy\build_and_deploy.ps1 -SqlAdminPassword "NoweHaslo123!"
   ```


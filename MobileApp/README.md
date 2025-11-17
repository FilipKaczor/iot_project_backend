# IoT Project - Mobile Application (React Native + Expo)

Mobile application for real-time IoT sensor data monitoring.

## Technology Stack

- **React Native** (Expo)
- **TypeScript**
- **React Navigation** - routing
- **Axios** - HTTP client
- **SignalR** - real-time communication
- **AsyncStorage** - local storage
- **React Native Chart Kit** - wykresy

## Requirements

- Node.js 18+
- npm or yarn
- Expo CLI: `npm install -g expo-cli`
- Expo Go app (on phone) or emulator

## Installation

```bash
cd MobileApp
npm install
```

## Configuration

### 1. Set API Address

Edit `src/config/api.ts`:

```typescript
// Development - lokalny backend
export const API_BASE_URL = 'https://localhost:7000';
export const SIGNALR_HUB_URL = 'https://localhost:7000/hubs/sensordata';

// Android emulator (używaj tego IP dla emulatora)
export const API_BASE_URL = 'https://10.0.2.2:7000';

// Fizyczne urządzenie (ustaw IP swojego komputera)
export const API_BASE_URL = 'https://192.168.1.100:7000';

// Azure (po deployment)
export const API_BASE_URL = 'https://iot-project-api.azurewebsites.net';
```

### 2. Start Backend

Ensure ASP.NET Core backend is running:

```bash
cd ../IoTProject.API
dotnet run
```

## Running Application

### Expo (recommended)

```bash
npm start
```

Scan QR code in **Expo Go** app (Android/iOS).

### Android Emulator

```bash
npm run android
```

### iOS Simulator (macOS only)

```bash
npm run ios
```

## Application Features

### Authorization
- Login screen
- New user registration
- JWT authentication
- Automatic session persistence

### Dashboard
- 4 sensor cards:
  - pH
  - Temperatura
  - Waga
  - Outside
- Connection status (online/offline)
- Real-time updates przez SignalR
- Pull-to-refresh

### Sensor Details
- Line chart of recent measurements
- Value history with timestamps
- Device ID
- Scroll for long lists

## Project Structure

```
MobileApp/
├── App.tsx                       # Główny komponent z nawigacją
├── app.json                      # Konfiguracja Expo
├── package.json
└── src/
    ├── config/
    │   └── api.ts                # Axios + SignalR setup
    └── screens/
        ├── LoginScreen.tsx       # Ekran logowania
        ├── RegisterScreen.tsx    # Ekran rejestracji
        ├── DashboardScreen.tsx   # Dashboard z czujnikami
        └── SensorDetailScreen.tsx # Szczegóły czujnika
```

## API Communication

### REST API (Axios)

```typescript
import { authAPI, sensorAPI } from './src/config/api';

// Login
const response = await authAPI.login('jan@example.com', 'password');
const { token, user } = response.data;

// Get sensor data (with token in header)
const data = await sensorAPI.getAllData(10);
```

### Real-time (SignalR)

```typescript
import { createSignalRConnection, startSignalRConnection } from './src/config/api';

// Create connection
const connection = await createSignalRConnection();

if (connection) {
  // Listen for events
  connection.on('ReceiveSensorUpdate', (data) => {
    console.log('Nowe dane:', data);
    // Update UI
  });

  connection.on('Connected', (data) => {
    console.log('Connected to SignalR:', data);
  });

  // Start connection
  await startSignalRConnection(connection);
}

// Stop connection
await stopSignalRConnection(connection);
```

## UI/UX

- **Design System**: Material Design inspired
- **Colors**: 
  - Primary: `#0078d4` (Azure Blue)
  - pH card: `#e3f2fd` (Light Blue)
  - Temp card: `#fff3e0` (Light Orange)
  - Weight card: `#f3e5f5` (Light Purple)
  - Outside card: `#e8f5e9` (Light Green)
- **Fonts**: System default (San Francisco/Roboto)
- **Responsiveness**: Works on various screen sizes

## Troubleshooting

### Problem: "Network request failed"

**Solution:**
1. Check if backend is running:
   ```bash
   curl https://localhost:7000/health
   ```
2. For Android emulator use `10.0.2.2` instead of `localhost`
3. For physical device use computer's IP address (not `localhost`)
4. Check CORS in backend (should be `AllowAnyOrigin()`)

### Problem: "Unable to resolve module"

**Solution:**
```bash
# Clear cache
npm start -- --reset-cache

# Lub
expo start -c

# Reinstall
rm -rf node_modules
npm install
```

### Problem: SignalR nie łączy się

**Solution:**
1. Check console logs
2. Verify JWT token is valid
3. Test SignalR endpoint in Postman:
   ```
   wss://localhost:7000/hubs/sensordata?access_token=YOUR_JWT_TOKEN
   ```
4. Check if backend has SignalR installed
5. Enable LogLevel.Debug w SignalR config:
   ```typescript
   .configureLogging(signalR.LogLevel.Debug)
   ```

### Problem: "Expo Go app won't load"

**Solution:**
1. Ensure phone and computer are on same WiFi network
2. Temporarily disable firewall
3. Use tunnel: `expo start --tunnel`

## Production Build

### Android APK

```bash
# Via Expo (EAS Build)
npm install -g eas-cli
eas build --platform android
```

### iOS

```bash
# Via Expo (requires Apple Developer Account)
eas build --platform ios
```

### Standalone (without Expo)

```bash
# Eject z Expo
expo eject

# Build Android
cd android
./gradlew assembleRelease

# Build iOS
cd ios
xcodebuild -workspace IoTProjectMobile.xcworkspace -scheme IoTProjectMobile -configuration Release
```

## Security

- JWT tokens in AsyncStorage (encrypted on device)
- HTTPS only in production
- Token automatically added to requests
- Auto-logout on 401/403
- Secure password input (secureTextEntry)

## TODO / Future Improvements

- [ ] Push notifications (Expo Notifications)
- [ ] Biometric authentication (FaceID/TouchID)
- [ ] Dark mode
- [ ] Offline support (cache danych)
- [ ] Charts - more options (bar, pie)
- [ ] Data export to CSV
- [ ] Filters and search in history
- [ ] Multi-language support (i18n)
- [ ] Unit tests (Jest)
- [ ] E2E tests (Detox)

## Support

- GitHub Issues

---

Version: 1.0.0


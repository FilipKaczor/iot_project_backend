/*
 * ESP32 - Azure IoT Hub Example
 * 
 * Ten przykład pokazuje jak połączyć ESP32 z Azure IoT Hub
 * i wysyłać dane z czujników.
 * 
 * Biblioteki:
 * - Azure IoT Hub (zainstaluj przez Arduino Library Manager)
 * - ArduinoJson
 * - WiFi (wbudowana)
 * 
 * Autor: IoT Project Team
 */

#include <WiFi.h>
#include <AzureIoTHub.h>
#include <AzureIoTProtocol_MQTT.h>
#include <iothubtransportmqtt.h>
#include <ArduinoJson.h>

// ============ KONFIGURACJA ============

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";           // Zmień na swoje WiFi
const char* password = "YOUR_WIFI_PASSWORD";   // Zmień na swoje hasło

// Azure IoT Hub - Device Connection String
// Pobierz z: Azure Portal → IoT Hub → Devices → [device] → Primary connection string
static const char* connectionString = "HostName=iot-project-hub.azure-devices.net;DeviceId=esp32-sensor-01;SharedAccessKey=your-key-here";

// Pins dla czujników (przykładowe)
const int PH_SENSOR_PIN = 34;      // Analog pin
const int TEMP_SENSOR_PIN = 35;    // Analog pin dla np. LM35
const int WEIGHT_SENSOR_PIN = 36;  // Analog pin dla HX711 (z load cell)

// Częstotliwość wysyłania danych (milisekundy)
const unsigned long SEND_INTERVAL = 5000;  // Co 5 sekund

// ============ ZMIENNE GLOBALNE ============

IOTHUB_CLIENT_LL_HANDLE iotHubClientHandle;
unsigned long lastSendTime = 0;
int messageCount = 0;

// ============ SETUP ============

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n=== ESP32 Azure IoT Hub Example ===\n");
  
  // Połącz z WiFi
  connectToWiFi();
  
  // Inicjalizuj czujniki
  initSensors();
  
  // Inicjalizuj Azure IoT Hub
  initAzureIoTHub();
  
  Serial.println("✅ Setup completed!\n");
}

// ============ GŁÓWNA PĘTLA ============

void loop() {
  // Obsługa IoT Hub (wysyłanie i odbieranie)
  IoTHubClient_LL_DoWork(iotHubClientHandle);
  
  // Wysyłaj dane co SEND_INTERVAL milisekund
  if (millis() - lastSendTime >= SEND_INTERVAL) {
    sendSensorData();
    lastSendTime = millis();
  }
  
  delay(100);
}

// ============ FUNKCJE POMOCNICZE ============

void connectToWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    ESP.restart();
  }
}

void initSensors() {
  Serial.println("Initializing sensors...");
  
  // Ustaw piny jako input
  pinMode(PH_SENSOR_PIN, INPUT);
  pinMode(TEMP_SENSOR_PIN, INPUT);
  pinMode(WEIGHT_SENSOR_PIN, INPUT);
  
  Serial.println("✅ Sensors initialized");
}

void initAzureIoTHub() {
  Serial.println("Initializing Azure IoT Hub...");
  
  // Inicjalizuj platformę IoT Hub
  if (platform_init() != 0) {
    Serial.println("❌ Failed to initialize platform");
    return;
  }
  
  // Utwórz handle klienta
  iotHubClientHandle = IoTHubClient_LL_CreateFromConnectionString(
    connectionString, 
    MQTT_Protocol
  );
  
  if (iotHubClientHandle == NULL) {
    Serial.println("❌ Failed to create IoT Hub client");
    return;
  }
  
  // Opcje konfiguracji
  bool traceOn = true;
  IoTHubClient_LL_SetOption(iotHubClientHandle, "logtrace", &traceOn);
  
  // Callback dla potwierdzenia wysłania
  IoTHubClient_LL_SetMessageCallback(iotHubClientHandle, receiveMessageCallback, NULL);
  
  Serial.println("✅ Azure IoT Hub initialized");
}

// ============ ODCZYT CZUJNIKÓW ============

float readPhSensor() {
  // Odczytaj wartość analog (0-4095 dla ESP32)
  int rawValue = analogRead(PH_SENSOR_PIN);
  
  // Konwersja do pH (0-14)
  // Wzór zależy od Twojego czujnika!
  // Przykład dla analogowego czujnika pH:
  float voltage = rawValue * (3.3 / 4095.0);
  float ph = 7.0 + ((2.5 - voltage) / 0.18);
  
  // Ograniczenia
  ph = constrain(ph, 0, 14);
  
  return ph;
}

float readTempSensor() {
  // Przykład dla LM35: 10mV per degree Celsius
  int rawValue = analogRead(TEMP_SENSOR_PIN);
  float voltage = rawValue * (3.3 / 4095.0);
  float temperatureC = voltage * 100.0;
  
  return temperatureC;
}

float readWeightSensor() {
  // Przykład dla HX711 + Load Cell
  // Tu powinieneś użyć biblioteki HX711
  int rawValue = analogRead(WEIGHT_SENSOR_PIN);
  
  // Konwersja do kg (kalibracja wymagana!)
  float weight = rawValue * 0.01;  // Przykładowa konwersja
  
  return weight;
}

float readOutsideSensor() {
  // Dodatkowy czujnik - np. wilgotność, ciśnienie, etc.
  // Przykład:
  return random(10, 30);  // Random dla demo
}

// ============ WYSYŁANIE DANYCH ============

void sendSensorData() {
  messageCount++;
  
  // Odczytaj czujniki
  float ph = readPhSensor();
  float temperature = readTempSensor();
  float weight = readWeightSensor();
  float outside = readOutsideSensor();
  
  // Utwórz JSON
  StaticJsonDocument<256> doc;
  doc["ph"] = ph;
  doc["temperature"] = temperature;
  doc["weight"] = weight;
  doc["outside"] = outside;
  doc["messageId"] = messageCount;
  doc["deviceId"] = "esp32-sensor-01";
  
  // Serialize do stringa
  char jsonBuffer[256];
  serializeJson(doc, jsonBuffer);
  
  // Wyślij do IoT Hub
  IOTHUB_MESSAGE_HANDLE messageHandle = IoTHubMessage_CreateFromString(jsonBuffer);
  
  if (messageHandle == NULL) {
    Serial.println("❌ Unable to create message");
    return;
  }
  
  // Dodaj właściwości (opcjonalne)
  MAP_HANDLE propMap = IoTHubMessage_Properties(messageHandle);
  Map_AddOrUpdate(propMap, "messageType", "telemetry");
  Map_AddOrUpdate(propMap, "deviceType", "esp32");
  
  // Wyślij
  if (IoTHubClient_LL_SendEventAsync(iotHubClientHandle, messageHandle, sendConfirmationCallback, NULL) != IOTHUB_CLIENT_OK) {
    Serial.println("❌ Failed to send message");
  } else {
    Serial.printf("📤 [%d] Sent: pH=%.2f, Temp=%.2f°C, Weight=%.2f kg, Outside=%.2f\n", 
                  messageCount, ph, temperature, weight, outside);
  }
  
  IoTHubMessage_Destroy(messageHandle);
}

// ============ CALLBACKS ============

void sendConfirmationCallback(IOTHUB_CLIENT_CONFIRMATION_RESULT result, void* userContextCallback) {
  if (result == IOTHUB_CLIENT_CONFIRMATION_OK) {
    Serial.println("✅ Message confirmed by IoT Hub");
  } else {
    Serial.printf("❌ Message failed: %d\n", result);
  }
}

IOTHUBMESSAGE_DISPOSITION_RESULT receiveMessageCallback(
  IOTHUB_MESSAGE_HANDLE message, 
  void* userContextCallback
) {
  const char* buffer;
  size_t size;
  
  if (IoTHubMessage_GetByteArray(message, (const unsigned char**)&buffer, &size) == IOTHUB_MESSAGE_OK) {
    Serial.printf("📨 Received message from cloud: %.*s\n", size, buffer);
    
    // Tutaj możesz parsować JSON i reagować na komendy
    // Np. zmienić częstotliwość wysyłania, włączyć/wyłączyć czujniki, etc.
  }
  
  return IOTHUBMESSAGE_ACCEPTED;
}

// ============ KONIEC ============


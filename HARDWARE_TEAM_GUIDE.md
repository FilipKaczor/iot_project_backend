# Hardware Team Guide - Raspberry Pi Integration

## Quick Start

### Connection Details

| Parameter | Value |
|-----------|-------|
| **Protocol** | MQTT 3.1.1 over TLS |
| **Port** | **8883** |
| **Host** | `{your-iot-hub}.azure-devices.net` |

---

## JSON Message Formats

All messages must include a `type` field to identify the sensor type.

### 1. Weight Sensor

```json
{
    "type": "weight",
    "device_id": "raspberry-pi-01",
    "weight_kg": 25.5,
    "timestamp": "2024-01-15T10:30:00Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| type | string | ✅ | Must be `"weight"` |
| device_id | string | ✅ | Your device identifier |
| weight_kg | float | ✅ | Weight in kilograms |
| timestamp | string | ❌ | ISO 8601 format (optional) |

---

### 2. Temperature Sensor (Internal)

```json
{
    "type": "temperature",
    "device_id": "raspberry-pi-01",
    "temperature_celsius": 18.5,
    "timestamp": "2024-01-15T10:30:00Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| type | string | ✅ | Must be `"temperature"` |
| device_id | string | ✅ | Your device identifier |
| temperature_celsius | float | ✅ | Temperature in °C |
| timestamp | string | ❌ | ISO 8601 format (optional) |

---

### 3. pH Sensor

```json
{
    "type": "ph",
    "device_id": "raspberry-pi-01",
    "ph_value": 4.2,
    "timestamp": "2024-01-15T10:30:00Z"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| type | string | ✅ | Must be `"ph"` |
| device_id | string | ✅ | Your device identifier |
| ph_value | float | ✅ | pH value (0-14) |
| timestamp | string | ❌ | ISO 8601 format (optional) |

---

### 4. Environment Sensor (External)

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

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| type | string | ✅ | Must be `"environment"` |
| device_id | string | ✅ | Your device identifier |
| humidity_percent | float | ✅ | Humidity 0-100% |
| temperature_celsius | float | ✅ | External temperature °C |
| pressure_hpa | float | ✅ | Pressure in hPa |
| timestamp | string | ❌ | ISO 8601 format (optional) |

---

## Python Example for Raspberry Pi

### Using Azure IoT SDK

```python
from azure.iot.device import IoTHubDeviceClient, Message
import json
import time

# Get this from Azure IoT Hub
CONNECTION_STRING = "HostName=your-hub.azure-devices.net;DeviceId=raspberry-pi-01;SharedAccessKey=xxx"

def send_sensor_data():
    # Connect to IoT Hub
    client = IoTHubDeviceClient.create_from_connection_string(CONNECTION_STRING)
    client.connect()
    
    try:
        # Send weight reading
        weight_data = {
            "type": "weight",
            "device_id": "raspberry-pi-01",
            "weight_kg": 25.5
        }
        msg = Message(json.dumps(weight_data))
        msg.content_encoding = "utf-8"
        msg.content_type = "application/json"
        client.send_message(msg)
        print("Sent weight data")
        
        # Send temperature reading
        temp_data = {
            "type": "temperature",
            "device_id": "raspberry-pi-01",
            "temperature_celsius": 18.5
        }
        msg = Message(json.dumps(temp_data))
        msg.content_encoding = "utf-8"
        msg.content_type = "application/json"
        client.send_message(msg)
        print("Sent temperature data")
        
        # Send pH reading
        ph_data = {
            "type": "ph",
            "device_id": "raspberry-pi-01",
            "ph_value": 4.2
        }
        msg = Message(json.dumps(ph_data))
        msg.content_encoding = "utf-8"
        msg.content_type = "application/json"
        client.send_message(msg)
        print("Sent pH data")
        
        # Send environment reading
        env_data = {
            "type": "environment",
            "device_id": "raspberry-pi-01",
            "humidity_percent": 65.0,
            "temperature_celsius": 22.0,
            "pressure_hpa": 1013.25
        }
        msg = Message(json.dumps(env_data))
        msg.content_encoding = "utf-8"
        msg.content_type = "application/json"
        client.send_message(msg)
        print("Sent environment data")
        
    finally:
        client.disconnect()

if __name__ == "__main__":
    send_sensor_data()
```

### Installation on Raspberry Pi

```bash
pip install azure-iot-device
```

---

## Continuous Monitoring Example

```python
from azure.iot.device import IoTHubDeviceClient, Message
import json
import time
import random  # Replace with actual sensor readings

CONNECTION_STRING = "your-connection-string"

def read_weight_sensor():
    # TODO: Replace with actual sensor code
    return round(random.uniform(20.0, 30.0), 2)

def read_temperature_sensor():
    # TODO: Replace with actual sensor code
    return round(random.uniform(15.0, 25.0), 1)

def read_ph_sensor():
    # TODO: Replace with actual sensor code
    return round(random.uniform(3.5, 5.5), 2)

def read_environment_sensor():
    # TODO: Replace with actual sensor code
    return {
        "humidity": round(random.uniform(40.0, 80.0), 1),
        "temperature": round(random.uniform(18.0, 28.0), 1),
        "pressure": round(random.uniform(990.0, 1030.0), 2)
    }

def main():
    client = IoTHubDeviceClient.create_from_connection_string(CONNECTION_STRING)
    client.connect()
    
    DEVICE_ID = "raspberry-pi-01"
    INTERVAL_SECONDS = 60  # Send data every minute
    
    print(f"Starting sensor monitoring (interval: {INTERVAL_SECONDS}s)")
    
    try:
        while True:
            # Read and send weight
            weight = read_weight_sensor()
            client.send_message(Message(json.dumps({
                "type": "weight",
                "device_id": DEVICE_ID,
                "weight_kg": weight
            })))
            
            # Read and send temperature
            temp = read_temperature_sensor()
            client.send_message(Message(json.dumps({
                "type": "temperature",
                "device_id": DEVICE_ID,
                "temperature_celsius": temp
            })))
            
            # Read and send pH
            ph = read_ph_sensor()
            client.send_message(Message(json.dumps({
                "type": "ph",
                "device_id": DEVICE_ID,
                "ph_value": ph
            })))
            
            # Read and send environment
            env = read_environment_sensor()
            client.send_message(Message(json.dumps({
                "type": "environment",
                "device_id": DEVICE_ID,
                "humidity_percent": env["humidity"],
                "temperature_celsius": env["temperature"],
                "pressure_hpa": env["pressure"]
            })))
            
            print(f"Data sent: weight={weight}kg, temp={temp}°C, pH={ph}, humidity={env['humidity']}%")
            time.sleep(INTERVAL_SECONDS)
            
    except KeyboardInterrupt:
        print("Stopping...")
    finally:
        client.disconnect()

if __name__ == "__main__":
    main()
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection refused | Check if IoT Hub hostname is correct |
| Authentication failed | Verify connection string / SAS token |
| Message not received | Check JSON format, especially `type` field |
| Data not in database | Check server logs for processing errors |

## Contact

Server API docs: `https://{server-url}/docs`


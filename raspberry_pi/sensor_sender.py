"""
Smart Brewery - Raspberry Pi Sensor Data Sender

This script sends sensor data to:
1. Azure IoT Hub via MQTT (for IoT demonstration)
2. HTTP API directly (for database storage)

Install:
    pip install azure-iot-device requests

Usage:
    python sensor_sender.py
"""

import json
import time
import requests
from datetime import datetime
from azure.iot.device import IoTHubDeviceClient, Message

# =============================================================================
# CONFIGURATION - Update these values!
# =============================================================================

# Azure IoT Hub connection string
IOT_HUB_CONNECTION_STRING = "HostName=smart-brewery-iothub.azure-devices.net;DeviceId=raspberry-pi-brewery;SharedAccessKey=nXM9dx6XX1b2ZhoA+yzA8/cE3QiGbeSrfp0pys5FOcs="

# API endpoint for data storage
API_URL = "https://smart-brewery.wittyforest-43b9cebb.westeurope.azurecontainerapps.io/mqtt/test"

# Device identifier
DEVICE_ID = "raspberry-pi-01"

# Send interval in seconds
SEND_INTERVAL = 60

# =============================================================================
# SENSOR READING FUNCTIONS - Replace with actual sensor code!
# =============================================================================

def read_weight_sensor():
    """Read from weight sensor (HX711 + Load Cell)"""
    # TODO: Replace with actual sensor reading
    # Example: return hx711.get_weight()
    import random
    return round(random.uniform(20.0, 30.0), 2)


def read_temperature_sensor():
    """Read from internal temperature sensor (DS18B20)"""
    # TODO: Replace with actual sensor reading
    # Example: return ds18b20.read_temp()
    import random
    return round(random.uniform(15.0, 25.0), 1)


def read_ph_sensor():
    """Read from pH sensor"""
    # TODO: Replace with actual sensor reading
    import random
    return round(random.uniform(3.5, 5.5), 2)


def read_environment_sensor():
    """Read from BME280 sensor (humidity, temperature, pressure)"""
    # TODO: Replace with actual sensor reading
    # Example:
    # bme = BME280()
    # return {
    #     "humidity": bme.humidity,
    #     "temperature": bme.temperature,
    #     "pressure": bme.pressure
    # }
    import random
    return {
        "humidity": round(random.uniform(40.0, 80.0), 1),
        "temperature": round(random.uniform(18.0, 28.0), 1),
        "pressure": round(random.uniform(990.0, 1030.0), 2)
    }


# =============================================================================
# DATA SENDING FUNCTIONS
# =============================================================================

def send_to_iot_hub(client, data):
    """Send data to Azure IoT Hub via MQTT"""
    try:
        message = Message(json.dumps(data))
        message.content_encoding = "utf-8"
        message.content_type = "application/json"
        client.send_message(message)
        print(f"  [IoT Hub] Sent: {data['type']}")
        return True
    except Exception as e:
        print(f"  [IoT Hub] Error: {e}")
        return False


def send_to_api(data):
    """Send data to HTTP API for database storage"""
    try:
        response = requests.post(API_URL, json=data, timeout=10)
        if response.status_code == 200:
            print(f"  [API] Saved: {data['type']}")
            return True
        else:
            print(f"  [API] Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"  [API] Error: {e}")
        return False


def send_sensor_data(client, sensor_type, data):
    """Send sensor data to both IoT Hub and API"""
    payload = {
        "type": sensor_type,
        "device_id": DEVICE_ID,
        **data,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    
    send_to_iot_hub(client, payload)
    send_to_api(payload)


# =============================================================================
# MAIN LOOP
# =============================================================================

def main():
    print("=" * 60)
    print("Smart Brewery - Sensor Data Sender")
    print("=" * 60)
    
    # Connect to IoT Hub
    print("\nConnecting to Azure IoT Hub...")
    client = IoTHubDeviceClient.create_from_connection_string(IOT_HUB_CONNECTION_STRING)
    client.connect()
    print("Connected!")
    
    print(f"\nSending data every {SEND_INTERVAL} seconds...")
    print("Press Ctrl+C to stop\n")
    
    try:
        while True:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            print(f"\n[{timestamp}] Reading sensors...")
            
            # Weight sensor
            weight = read_weight_sensor()
            send_sensor_data(client, "weight", {"weight_kg": weight})
            
            # Temperature sensor (internal)
            temp = read_temperature_sensor()
            send_sensor_data(client, "temperature", {"temperature_celsius": temp})
            
            # pH sensor
            ph = read_ph_sensor()
            send_sensor_data(client, "ph", {"ph_value": ph})
            
            # Environment sensor (external)
            env = read_environment_sensor()
            send_sensor_data(client, "environment", {
                "humidity_percent": env["humidity"],
                "temperature_celsius": env["temperature"],
                "pressure_hpa": env["pressure"]
            })
            
            print(f"\nWaiting {SEND_INTERVAL} seconds...")
            time.sleep(SEND_INTERVAL)
            
    except KeyboardInterrupt:
        print("\n\nStopping...")
    finally:
        client.disconnect()
        print("Disconnected from IoT Hub")


if __name__ == "__main__":
    main()


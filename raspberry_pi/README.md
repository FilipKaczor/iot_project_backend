# Smart Brewery - Raspberry Pi Setup

## Quick Start

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Run the sensor sender
```bash
python sensor_sender.py
```

## Configuration

Edit `sensor_sender.py` and update:
- `IOT_HUB_CONNECTION_STRING` - your IoT Hub device connection string
- `API_URL` - your API endpoint
- `DEVICE_ID` - unique device identifier
- `SEND_INTERVAL` - how often to send data (seconds)

## Sensor Integration

Replace the placeholder functions with actual sensor code:

### Weight Sensor (HX711 + Load Cell)
```python
from hx711 import HX711
hx = HX711(dout_pin=5, pd_sck_pin=6)

def read_weight_sensor():
    return hx.get_weight_mean(5)
```

### Temperature Sensor (DS18B20)
```python
from w1thermsensor import W1ThermSensor
sensor = W1ThermSensor()

def read_temperature_sensor():
    return sensor.get_temperature()
```

### Environment Sensor (BME280)
```python
import board
from adafruit_bme280 import basic as adafruit_bme280
i2c = board.I2C()
bme280 = adafruit_bme280.Adafruit_BME280_I2C(i2c)

def read_environment_sensor():
    return {
        "humidity": bme280.relative_humidity,
        "temperature": bme280.temperature,
        "pressure": bme280.pressure
    }
```

## Data Flow

```
Sensors → Raspberry Pi → [MQTT] → Azure IoT Hub
                       → [HTTP] → API → Database
```

Both paths are used to ensure:
1. IoT Hub demonstrates MQTT knowledge
2. HTTP ensures data is stored in database


"""
MQTT Handler for Azure IoT Hub

This module handles incoming MQTT messages from Raspberry Pi devices
and stores sensor data in the database.

=== FOR HARDWARE TEAM ===

Azure IoT Hub Connection Details:
- Protocol: MQTT 3.1.1
- Port: 8883 (TLS)
- Hostname: {your-iot-hub-name}.azure-devices.net

MQTT Topics for sending data:
- devices/{device-id}/messages/events/

JSON Payload Formats:

1. Weight Sensor:
{
    "type": "weight",
    "device_id": "raspberry-pi-01",
    "weight_kg": 25.5,
    "timestamp": "2024-01-15T10:30:00Z"  // optional, ISO 8601 format
}

2. Temperature Sensor (Internal):
{
    "type": "temperature",
    "device_id": "raspberry-pi-01",
    "temperature_celsius": 18.5,
    "timestamp": "2024-01-15T10:30:00Z"
}

3. pH Sensor:
{
    "type": "ph",
    "device_id": "raspberry-pi-01",
    "ph_value": 4.2,
    "timestamp": "2024-01-15T10:30:00Z"
}

4. Environment Sensor (External - humidity, temperature, pressure):
{
    "type": "environment",
    "device_id": "raspberry-pi-01",
    "humidity_percent": 65.0,
    "temperature_celsius": 22.0,
    "pressure_hpa": 1013.25,
    "timestamp": "2024-01-15T10:30:00Z"
}

"""

import json
import logging
from datetime import datetime
from typing import Optional
from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.readings import (
    WeightReading, TemperatureReading, PhReading, EnvironmentReading
)

logger = logging.getLogger(__name__)


class MqttHandler:
    """Handles MQTT messages and stores readings in database"""
    
    @staticmethod
    def process_message(payload: str) -> bool:
        """
        Process incoming MQTT message and store in database
        
        Args:
            payload: JSON string with sensor data
            
        Returns:
            True if message processed successfully, False otherwise
        """
        try:
            data = json.loads(payload)
            message_type = data.get("type")
            
            if not message_type:
                logger.error("Message missing 'type' field")
                return False
            
            db = SessionLocal()
            try:
                if message_type == "weight":
                    return MqttHandler._store_weight(db, data)
                elif message_type == "temperature":
                    return MqttHandler._store_temperature(db, data)
                elif message_type == "ph":
                    return MqttHandler._store_ph(db, data)
                elif message_type == "environment":
                    return MqttHandler._store_environment(db, data)
                else:
                    logger.error(f"Unknown message type: {message_type}")
                    return False
            finally:
                db.close()
                
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON payload: {e}")
            return False
        except Exception as e:
            logger.error(f"Error processing message: {e}")
            return False
    
    @staticmethod
    def _store_weight(db: Session, data: dict) -> bool:
        reading = WeightReading(
            device_id=data.get("device_id", "unknown"),
            weight_kg=data["weight_kg"]
        )
        db.add(reading)
        db.commit()
        logger.info(f"Stored weight reading: {data['weight_kg']} kg")
        return True
    
    @staticmethod
    def _store_temperature(db: Session, data: dict) -> bool:
        reading = TemperatureReading(
            device_id=data.get("device_id", "unknown"),
            temperature_celsius=data["temperature_celsius"]
        )
        db.add(reading)
        db.commit()
        logger.info(f"Stored temperature reading: {data['temperature_celsius']} °C")
        return True
    
    @staticmethod
    def _store_ph(db: Session, data: dict) -> bool:
        reading = PhReading(
            device_id=data.get("device_id", "unknown"),
            ph_value=data["ph_value"]
        )
        db.add(reading)
        db.commit()
        logger.info(f"Stored pH reading: {data['ph_value']}")
        return True
    
    @staticmethod
    def _store_environment(db: Session, data: dict) -> bool:
        reading = EnvironmentReading(
            device_id=data.get("device_id", "unknown"),
            humidity_percent=data["humidity_percent"],
            temperature_celsius=data["temperature_celsius"],
            pressure_hpa=data["pressure_hpa"]
        )
        db.add(reading)
        db.commit()
        logger.info(f"Stored environment reading: {data['humidity_percent']}% humidity")
        return True


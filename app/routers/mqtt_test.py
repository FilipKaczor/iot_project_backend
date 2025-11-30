"""
MQTT Test Endpoint - For local testing before Azure IoT Hub deployment

This endpoint simulates receiving MQTT messages via HTTP POST.
Hardware team can use this to test their JSON payloads locally.

Usage:
    POST /mqtt/test
    Content-Type: application/json
    
    Body: Same JSON format as MQTT messages
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Literal
from app.services.mqtt_handler import MqttHandler
import json

router = APIRouter(prefix="/mqtt", tags=["MQTT Test"])


class WeightPayload(BaseModel):
    type: Literal["weight"]
    device_id: str
    weight_kg: float
    timestamp: Optional[str] = None


class TemperaturePayload(BaseModel):
    type: Literal["temperature"]
    device_id: str
    temperature_celsius: float
    timestamp: Optional[str] = None


class PhPayload(BaseModel):
    type: Literal["ph"]
    device_id: str
    ph_value: float = Field(ge=0, le=14)
    timestamp: Optional[str] = None


class EnvironmentPayload(BaseModel):
    type: Literal["environment"]
    device_id: str
    humidity_percent: float = Field(ge=0, le=100)
    temperature_celsius: float
    pressure_hpa: float
    timestamp: Optional[str] = None


class GenericSensorPayload(BaseModel):
    """Generic payload that accepts any sensor type"""
    type: str
    device_id: str
    
    class Config:
        extra = "allow"  # Allow additional fields


@router.post("/test")
async def test_mqtt_message(payload: dict):
    """
    Test MQTT message processing
    
    Send sensor data in the same JSON format as MQTT messages.
    Data will be stored in the database.
    
    **Example payloads:**
    
    Weight:
    ```json
    {"type": "weight", "device_id": "rpi-01", "weight_kg": 25.5}
    ```
    
    Temperature:
    ```json
    {"type": "temperature", "device_id": "rpi-01", "temperature_celsius": 18.5}
    ```
    
    pH:
    ```json
    {"type": "ph", "device_id": "rpi-01", "ph_value": 4.2}
    ```
    
    Environment:
    ```json
    {"type": "environment", "device_id": "rpi-01", "humidity_percent": 65.0, "temperature_celsius": 22.0, "pressure_hpa": 1013.25}
    ```
    """
    
    # Validate required fields
    if "type" not in payload:
        raise HTTPException(status_code=400, detail="Missing 'type' field")
    if "device_id" not in payload:
        raise HTTPException(status_code=400, detail="Missing 'device_id' field")
    
    sensor_type = payload.get("type")
    
    # Validate based on type
    required_fields = {
        "weight": ["weight_kg"],
        "temperature": ["temperature_celsius"],
        "ph": ["ph_value"],
        "environment": ["humidity_percent", "temperature_celsius", "pressure_hpa"]
    }
    
    if sensor_type not in required_fields:
        raise HTTPException(
            status_code=400, 
            detail=f"Unknown type '{sensor_type}'. Valid types: weight, temperature, ph, environment"
        )
    
    missing = [f for f in required_fields[sensor_type] if f not in payload]
    if missing:
        raise HTTPException(
            status_code=400,
            detail=f"Missing required fields for '{sensor_type}': {missing}"
        )
    
    # Process through MQTT handler
    payload_json = json.dumps(payload)
    success = MqttHandler.process_message(payload_json)
    
    if success:
        return {
            "status": "success",
            "message": f"Sensor data stored successfully",
            "type": sensor_type,
            "device_id": payload.get("device_id")
        }
    else:
        raise HTTPException(
            status_code=500,
            detail="Failed to store sensor data"
        )


@router.post("/test/batch")
async def test_mqtt_batch(payloads: list[dict]):
    """
    Test multiple MQTT messages at once
    
    Send an array of sensor payloads.
    """
    results = []
    
    for i, payload in enumerate(payloads):
        try:
            if "type" not in payload or "device_id" not in payload:
                results.append({
                    "index": i,
                    "status": "error",
                    "detail": "Missing 'type' or 'device_id'"
                })
                continue
            
            payload_json = json.dumps(payload)
            success = MqttHandler.process_message(payload_json)
            
            results.append({
                "index": i,
                "status": "success" if success else "error",
                "type": payload.get("type"),
                "device_id": payload.get("device_id")
            })
        except Exception as e:
            results.append({
                "index": i,
                "status": "error",
                "detail": str(e)
            })
    
    success_count = sum(1 for r in results if r["status"] == "success")
    
    return {
        "total": len(payloads),
        "success": success_count,
        "failed": len(payloads) - success_count,
        "results": results
    }


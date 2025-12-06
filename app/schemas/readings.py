"""
Sensor Reading Schemas
"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Literal


# Request schemas
class SensorDataCreate(BaseModel):
    """Schema for sensor data from Raspberry Pi"""
    type: Literal["temperature", "ph", "weight", "outsideTemp", "humidity", "pressure"]
    value: float = Field(..., description="Sensor value")
    device_id: str = Field(default="raspberry-pi-brewery", description="Device identifier")


# Response schemas
class TemperatureReadingResponse(BaseModel):
    """Temperature reading response"""
    id: int
    device_id: str
    temperature_celsius: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


class PhReadingResponse(BaseModel):
    """pH reading response"""
    id: int
    device_id: str
    ph_value: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


class WeightReadingResponse(BaseModel):
    """Weight reading response"""
    id: int
    device_id: str
    weight_kg: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


class OutsideTemperatureReadingResponse(BaseModel):
    """Outside temperature reading response"""
    id: int
    device_id: str
    temperature_celsius: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


class HumidityReadingResponse(BaseModel):
    """Humidity reading response"""
    id: int
    device_id: str
    humidity_percent: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


class PressureReadingResponse(BaseModel):
    """Pressure reading response"""
    id: int
    device_id: str
    pressure_hpa: float
    timestamp: datetime
    
    class Config:
        from_attributes = True

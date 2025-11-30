from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


class ReadingsQuery(BaseModel):
    """Query parameters for fetching readings"""
    days: int = Field(default=7, ge=1, le=365, description="Number of days to fetch data")


# Weight Schemas
class WeightReadingCreate(BaseModel):
    device_id: str
    weight_kg: float


class WeightReadingResponse(BaseModel):
    id: int
    device_id: str
    weight_kg: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


# Temperature Schemas (internal sensor)
class TemperatureReadingCreate(BaseModel):
    device_id: str
    temperature_celsius: float


class TemperatureReadingResponse(BaseModel):
    id: int
    device_id: str
    temperature_celsius: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


# pH Schemas
class PhReadingCreate(BaseModel):
    device_id: str
    ph_value: float = Field(ge=0, le=14, description="pH value between 0 and 14")


class PhReadingResponse(BaseModel):
    id: int
    device_id: str
    ph_value: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


# Environment Schemas (external sensor: humidity, temperature, pressure)
class EnvironmentReadingCreate(BaseModel):
    device_id: str
    humidity_percent: float = Field(ge=0, le=100)
    temperature_celsius: float
    pressure_hpa: float


class EnvironmentReadingResponse(BaseModel):
    id: int
    device_id: str
    humidity_percent: float
    temperature_celsius: float
    pressure_hpa: float
    timestamp: datetime
    
    class Config:
        from_attributes = True


# MQTT Message Schemas (for hardware team)
class MqttWeightMessage(BaseModel):
    """JSON format for weight data from Raspberry Pi"""
    device_id: str
    weight_kg: float
    timestamp: Optional[str] = None


class MqttTemperatureMessage(BaseModel):
    """JSON format for temperature data from Raspberry Pi"""
    device_id: str
    temperature_celsius: float
    timestamp: Optional[str] = None


class MqttPhMessage(BaseModel):
    """JSON format for pH data from Raspberry Pi"""
    device_id: str
    ph_value: float
    timestamp: Optional[str] = None


class MqttEnvironmentMessage(BaseModel):
    """JSON format for environment data from Raspberry Pi"""
    device_id: str
    humidity_percent: float
    temperature_celsius: float
    pressure_hpa: float
    timestamp: Optional[str] = None


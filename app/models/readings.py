from sqlalchemy import Column, Integer, Float, DateTime, String
from sqlalchemy.sql import func
from app.database import Base


class WeightReading(Base):
    """Weight sensor readings from the brewery"""
    __tablename__ = "weight_readings"
    
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(100), index=True, nullable=False)
    weight_kg = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)


class TemperatureReading(Base):
    """Internal temperature sensor readings"""
    __tablename__ = "temperature_readings"
    
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(100), index=True, nullable=False)
    temperature_celsius = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)


class PhReading(Base):
    """pH sensor readings from inside the brewery"""
    __tablename__ = "ph_readings"
    
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(100), index=True, nullable=False)
    ph_value = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)


class EnvironmentReading(Base):
    """External environment sensor: humidity, temperature, pressure"""
    __tablename__ = "environment_readings"
    
    id = Column(Integer, primary_key=True, index=True)
    device_id = Column(String(100), index=True, nullable=False)
    humidity_percent = Column(Float, nullable=False)
    temperature_celsius = Column(Float, nullable=False)
    pressure_hpa = Column(Float, nullable=False)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)


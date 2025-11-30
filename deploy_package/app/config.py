import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Smart Brewery IoT Server"
    DEBUG: bool = False
    
    # Database - Azure SQL
    DATABASE_URL: str = "sqlite:///./smart_brewery.db"  # Default for local dev
    # For Azure SQL: "mssql+pyodbc://user:password@server.database.windows.net/dbname?driver=ODBC+Driver+18+for+SQL+Server"
    
    # JWT Authentication
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
    
    # Azure IoT Hub MQTT Settings
    IOT_HUB_HOSTNAME: str = ""  # e.g., "your-hub.azure-devices.net"
    IOT_HUB_DEVICE_ID: str = "raspberry-pi-brewery"
    IOT_HUB_SAS_TOKEN: str = ""
    
    # MQTT Topics for sensor data
    MQTT_TOPIC_WEIGHT: str = "devices/{device_id}/messages/events/weight"
    MQTT_TOPIC_TEMPERATURE: str = "devices/{device_id}/messages/events/temperature"
    MQTT_TOPIC_PH: str = "devices/{device_id}/messages/events/ph"
    MQTT_TOPIC_ENVIRONMENT: str = "devices/{device_id}/messages/events/environment"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


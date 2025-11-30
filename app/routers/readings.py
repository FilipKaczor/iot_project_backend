from datetime import datetime, timedelta
from typing import List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.services.auth import get_current_user
from app.models.user import User
from app.models.readings import (
    WeightReading, TemperatureReading, PhReading, EnvironmentReading
)
from app.schemas.readings import (
    WeightReadingResponse, TemperatureReadingResponse,
    PhReadingResponse, EnvironmentReadingResponse
)

router = APIRouter(prefix="/readings", tags=["Sensor Readings"])


@router.get("/weight", response_model=List[WeightReadingResponse])
async def get_weight_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get weight sensor readings
    
    - **days**: Number of days of historical data (1-365, default: 7)
    
    Requires: Bearer token in Authorization header
    """
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(WeightReading).filter(
        WeightReading.timestamp >= since
    ).order_by(WeightReading.timestamp.desc()).all()
    
    return readings


@router.get("/temperature", response_model=List[TemperatureReadingResponse])
async def get_temperature_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get internal temperature sensor readings
    
    - **days**: Number of days of historical data (1-365, default: 7)
    
    Requires: Bearer token in Authorization header
    """
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(TemperatureReading).filter(
        TemperatureReading.timestamp >= since
    ).order_by(TemperatureReading.timestamp.desc()).all()
    
    return readings


@router.get("/ph", response_model=List[PhReadingResponse])
async def get_ph_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get pH sensor readings
    
    - **days**: Number of days of historical data (1-365, default: 7)
    
    Requires: Bearer token in Authorization header
    """
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(PhReading).filter(
        PhReading.timestamp >= since
    ).order_by(PhReading.timestamp.desc()).all()
    
    return readings


@router.get("/environment", response_model=List[EnvironmentReadingResponse])
async def get_environment_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get external environment sensor readings (humidity, temperature, pressure)
    
    - **days**: Number of days of historical data (1-365, default: 7)
    
    Requires: Bearer token in Authorization header
    """
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(EnvironmentReading).filter(
        EnvironmentReading.timestamp >= since
    ).order_by(EnvironmentReading.timestamp.desc()).all()
    
    return readings


@router.delete("/clear", summary="Clear all test data")
async def clear_all_readings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Clear all sensor readings from the database.
    Use this to remove test/simulation data before production.
    
    Requires: Bearer token in Authorization header
    """
    weight_count = db.query(WeightReading).delete()
    temp_count = db.query(TemperatureReading).delete()
    ph_count = db.query(PhReading).delete()
    env_count = db.query(EnvironmentReading).delete()
    db.commit()
    
    return {
        "status": "success",
        "deleted": {
            "weight": weight_count,
            "temperature": temp_count,
            "ph": ph_count,
            "environment": env_count
        }
    }


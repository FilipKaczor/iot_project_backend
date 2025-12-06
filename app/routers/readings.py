"""
Readings Endpoints - Get sensor data
"""
from datetime import datetime, timedelta
from typing import List
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.auth import get_current_user
from app.models.user import User
from app.models.readings import (
    TemperatureReading,
    PhReading,
    WeightReading,
    OutsideTemperatureReading,
    HumidityReading,
    PressureReading
)
from app.schemas.readings import (
    TemperatureReadingResponse,
    PhReadingResponse,
    WeightReadingResponse,
    OutsideTemperatureReadingResponse,
    HumidityReadingResponse,
    PressureReadingResponse
)

router = APIRouter(prefix="/readings", tags=["Readings"])


@router.get("/temperature", response_model=List[TemperatureReadingResponse])
async def get_temperature_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get temperature readings for the last N days"""
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
    """Get pH readings for the last N days"""
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(PhReading).filter(
        PhReading.timestamp >= since
    ).order_by(PhReading.timestamp.desc()).all()
    return readings


@router.get("/weight", response_model=List[WeightReadingResponse])
async def get_weight_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get weight readings for the last N days"""
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(WeightReading).filter(
        WeightReading.timestamp >= since
    ).order_by(WeightReading.timestamp.desc()).all()
    return readings


@router.get("/outsideTemp", response_model=List[OutsideTemperatureReadingResponse])
async def get_outside_temperature_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get outside temperature readings for the last N days"""
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(OutsideTemperatureReading).filter(
        OutsideTemperatureReading.timestamp >= since
    ).order_by(OutsideTemperatureReading.timestamp.desc()).all()
    return readings


@router.get("/humidity", response_model=List[HumidityReadingResponse])
async def get_humidity_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get humidity readings for the last N days"""
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(HumidityReading).filter(
        HumidityReading.timestamp >= since
    ).order_by(HumidityReading.timestamp.desc()).all()
    return readings


@router.get("/pressure", response_model=List[PressureReadingResponse])
async def get_pressure_readings(
    days: int = Query(default=7, ge=1, le=365, description="Number of days to fetch"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get pressure readings for the last N days"""
    since = datetime.utcnow() - timedelta(days=days)
    readings = db.query(PressureReading).filter(
        PressureReading.timestamp >= since
    ).order_by(PressureReading.timestamp.desc()).all()
    return readings

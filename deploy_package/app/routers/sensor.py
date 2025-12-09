"""
Sensor Data Endpoint - For Raspberry Pi
"""
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.readings import SensorDataCreate
from app.models.readings import (
    TemperatureReading,
    PhReading,
    WeightReading,
    OutsideTemperatureReading,
    HumidityReading,
    PressureReading
)

router = APIRouter(prefix="/sensor", tags=["Sensor Data"])


@router.post("/data")
async def receive_sensor_data(
    data: SensorDataCreate,
    db: Session = Depends(get_db)
):
    """
    Receive sensor data from Raspberry Pi via curl
    
    **Supported types:**
    - temperature: Internal temperature
    - ph: pH value
    - weight: Weight in kg
    - outsideTemp: Outside temperature
    - humidity: Humidity percentage
    - pressure: Pressure in hPa
    
    **Example:**
    ```bash
    curl -X POST https://your-api.com/sensor/data \\
      -H "Content-Type: application/json" \\
      -d '{"type": "temperature", "value": 22.5, "device_id": "raspberry-pi-brewery"}'
    ```
    """
    try:
        device_id = data.device_id or "raspberry-pi-brewery"
        
        if data.type == "temperature":
            reading = TemperatureReading(
                device_id=device_id,
                temperature_celsius=data.value
            )
        elif data.type == "ph":
            reading = PhReading(
                device_id=device_id,
                ph_value=data.value
            )
        elif data.type == "weight":
            reading = WeightReading(
                device_id=device_id,
                weight_kg=data.value
            )
        elif data.type == "outsideTemp":
            reading = OutsideTemperatureReading(
                device_id=device_id,
                temperature_celsius=data.value
            )
        elif data.type == "humidity":
            reading = HumidityReading(
                device_id=device_id,
                humidity_percent=data.value
            )
        elif data.type == "pressure":
            reading = PressureReading(
                device_id=device_id,
                pressure_hpa=data.value
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Unknown sensor type: {data.type}"
            )
        
        db.add(reading)
        db.commit()
        db.refresh(reading)
        
        return {
            "status": "success",
            "message": f"{data.type} data stored successfully",
            "id": reading.id
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Failed to store sensor data: {str(e)}"
        )


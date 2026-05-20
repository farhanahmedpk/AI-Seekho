"""
Sensor Routes — CRUD endpoints for sensor readings.

Used by the Flutter app and the data simulator to push/query sensor data.
"""

from datetime import datetime
from fastapi import APIRouter, Request

from app.models.schemas import SensorReadingCreate

router = APIRouter()


@router.post("/readings", summary="Push a new sensor reading")
async def create_reading(reading: SensorReadingCreate, request: Request):
    """
    Post a new temperature reading from a sensor.
    This is used by the simulator or real IoT devices.
    """
    firebase = request.app.state.firebase

    reading_data = {
        **reading.model_dump(),
        "timestamp": datetime.utcnow().isoformat(),
    }

    key = firebase.push_sensor_reading(reading.truck_id, reading_data)

    return {
        "status": "success",
        "reading_key": key,
        "truck_id": reading.truck_id,
        "temperature": reading.temperature,
    }


@router.get("/readings/{truck_id}", summary="Get readings for a truck")
async def get_readings(truck_id: str, request: Request):
    """Get all sensor readings for a specific truck."""
    firebase = request.app.state.firebase
    data = firebase.get_latest_readings(truck_id)
    return {"truck_id": truck_id, "readings": data or {}}


@router.get("/readings", summary="Get readings for all trucks")
async def get_all_readings(request: Request):
    """Get sensor readings for all trucks."""
    firebase = request.app.state.firebase
    data = firebase.get_all_trucks()
    return {"trucks": data or {}}

from app.routers.health import router as health_router
from app.routers.auth import router as auth_router
from app.routers.readings import router as readings_router
from app.routers.mqtt_test import router as mqtt_test_router

__all__ = ["health_router", "auth_router", "readings_router", "mqtt_test_router"]


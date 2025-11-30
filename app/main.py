"""
Smart Brewery IoT Server

Azure-hosted server for smart brewery IoT system.
Receives sensor data via MQTT from Raspberry Pi and provides REST API for mobile app.
"""

import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.database import init_db
from app.routers import health_router, auth_router, readings_router, mqtt_test_router

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    logger.info("Starting Smart Brewery IoT Server...")
    init_db()
    logger.info("Database initialized")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Smart Brewery IoT Server...")


app = FastAPI(
    title=settings.APP_NAME,
    description="""
## Smart Brewery IoT Server

REST API for the Smart Brewery monitoring system.

### Features:
- **Authentication**: Register, login, and manage user accounts
- **Sensor Data**: Access historical readings from brewery sensors
- **Real-time Monitoring**: Integration with Azure IoT Hub for live data

### Sensor Types:
- **Weight**: Monitor fermenter weight
- **Temperature (Internal)**: Track fermentation temperature
- **pH**: Monitor acidity levels
- **Environment (External)**: Humidity, temperature, and pressure

### Authentication:
All sensor data endpoints require Bearer token authentication.
1. Register at `/register`
2. Login at `/login` to get your token
3. Include `Authorization: Bearer <token>` header in requests
    """,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health_router)
app.include_router(auth_router)
app.include_router(readings_router)
app.include_router(mqtt_test_router)  # For local testing


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint - redirects to API documentation"""
    return {
        "message": "Smart Brewery IoT Server",
        "documentation": "/docs",
        "health": "/health"
    }


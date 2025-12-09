"""
Smart Brewery IoT Server

Simple REST API for receiving sensor data from Raspberry Pi
and providing endpoints to read historical data.
"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.database import init_db
from app.routers import auth, sensor, readings, health

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

REST API for receiving sensor data from Raspberry Pi and reading historical data.

### Features:
- **Sensor Data**: POST endpoint for Raspberry Pi to send sensor readings
- **Readings**: GET endpoints to retrieve historical sensor data
- **Authentication**: Register, login, update user profile

### Sensor Types:
- temperature: Internal temperature
- ph: pH value
- weight: Weight in kg
- outsideTemp: Outside temperature
- humidity: Humidity percentage
- pressure: Pressure in hPa

### Usage:
1. Register at `/register`
2. Login at `/login` to get access token
3. Send sensor data to `/sensor/data` (no auth required)
4. Read data from `/readings/*` (requires Bearer token)
    """,
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(sensor.router)
app.include_router(readings.router)


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "message": "Smart Brewery IoT Server",
        "version": settings.VERSION,
        "documentation": "/docs",
        "health": "/health"
    }


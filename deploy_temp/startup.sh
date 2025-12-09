#!/bin/bash
# Azure Web App Startup Script
# Uses PORT environment variable set by Azure

# Get port from environment (Azure sets this automatically)
PORT=${PORT:-8000}

# Start uvicorn with gunicorn workers for production
exec gunicorn main:app \
    --workers 4 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:$PORT \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -


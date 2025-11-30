"""
Main entry point for Azure App Service deployment.
This file imports and re-exports the FastAPI application from app.main
"""
import sys
import os

# Add the current directory to the Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.main import app

# Re-export for gunicorn
__all__ = ['app']


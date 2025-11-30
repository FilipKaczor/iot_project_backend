"""
Azure Function to process IoT Hub messages

This Azure Function is triggered by messages arriving at Azure IoT Hub
and processes them to store sensor data in the database.

Deploy this as an Azure Function with IoT Hub trigger.
"""

import logging
import azure.functions as func
from app.services.mqtt_handler import MqttHandler

logger = logging.getLogger(__name__)


def main(event: func.EventHubMessage):
    """
    Azure Function entry point - triggered by IoT Hub messages
    
    This function is automatically triggered when Raspberry Pi
    sends data to Azure IoT Hub via MQTT.
    """
    try:
        # Get message body
        message_body = event.get_body().decode('utf-8')
        logger.info(f"Received IoT Hub message: {message_body}")
        
        # Process the message
        success = MqttHandler.process_message(message_body)
        
        if success:
            logger.info("Message processed successfully")
        else:
            logger.error("Failed to process message")
            
    except Exception as e:
        logger.error(f"Error in Azure Function: {e}")
        raise


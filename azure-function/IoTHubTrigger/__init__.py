import logging
import requests
import json
import azure.functions as func

API_URL = "https://smart-brewery.wittyforest-43b9cebb.westeurope.azurecontainerapps.io/mqtt/test"


def main(event: func.EventHubEvent):
    """
    Azure Function triggered by IoT Hub messages.
    Forwards sensor data to our API which stores it in database.
    """
    try:
        message_body = event.get_body().decode('utf-8')
        logging.info(f'IoT Hub message received: {message_body}')
        
        # Parse the JSON data
        data = json.loads(message_body)
        
        # Forward to our API
        response = requests.post(
            API_URL,
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            logging.info(f'Data saved to database: {response.json()}')
        else:
            logging.error(f'API error: {response.status_code} - {response.text}')
            
    except json.JSONDecodeError as e:
        logging.error(f'Invalid JSON: {e}')
    except requests.RequestException as e:
        logging.error(f'API request failed: {e}')
    except Exception as e:
        logging.error(f'Error: {e}')


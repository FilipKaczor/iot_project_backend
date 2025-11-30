import logging
import requests
import json
import azure.functions as func

def main(event: func.EventHubEvent):
    msg = event.get_body().decode("utf-8")
    logging.info(f"Received: {msg}")
    try:
        data = json.loads(msg)
        r = requests.post(
            "https://smart-brewery.wittyforest-43b9cebb.westeurope.azurecontainerapps.io/mqtt/test",
            json=data,
            timeout=10
        )
        logging.info(f"API response: {r.status_code}")
    except Exception as e:
        logging.error(f"Error: {e}")
